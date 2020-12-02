#INCLUDE "totvs.ch"

STATIC cPathRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} CFINE20
Rotina de validação na geração do arquivo de pagamento Remessa e Retorno
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function CFINE20(nTipo,nOpcx)

	Local lRet		:= .T.
	Local cTab		:= ""
	Local cNumBor	:= ""
	Local cValGerArq := SuperGetMV("CI_VALARQ",.F.,.T.)

	IF nTipo==1 // Remessa

		DO CASE
		CASE nOpcx==1
			IF !EMPTY(MV_PAR01) .AND. !EMPTY(MV_PAR02)
				DbSelectArea("SZL")
				DbSetOrder(1)
				If DbSeek(xFilial("SZL")+Alltrim(UPPER(mv_par03)))
					dbSelectArea("SEA")
					dbSetOrder(1)
					dbSeek(xFilial("SEA")+MV_PAR01,.T.)
					While !Eof() .And. SEA->EA_NUMBOR <= MV_PAR02 .and. SEA->EA_FILIAL == xFilial("SEA")
						cNumBor:= SEA->EA_NUMBOR
						If SZL->ZL_BANCO <> SEA->EA_PORTADO
							msgbox("Bordero nr."+SEA->EA_NUMBOR+" nao pertence ao arquivo de configuracao do banco "+SZL->ZL_BANCO+" !!!", "ATENCAO")
							lRet:= .F.
						EndIf

						IF SEA->EA_MODELO == "99"
							msgbox("Bordero nr."+SEA->EA_NUMBOR+" nao pertence ao layout de geracao para Transmissao ao Banco!!!", "ATENCAO")
							lRet:= .F.
						EndIf

						// Verifica aprovação dos titulos
						If cValGerArq
							cTab:= GetNextAlias()
							BeginSql Alias cTab
							SELECT COUNT(*) AS TOTSE2 FROM %TABLE:SE2% SE2
							WHERE E2_NUMBOR=%exp:cNumBor%
							AND E2_XSTSAPV!='2'
							AND SE2.D_E_L_E_T_ =''
							EndSql

							// GETLastQuery()[2]
							(cTab)->(dbSelectArea((cTab)))
							(cTab)->(dbGoTop())
							IF (cTab)->TOTSE2 > 0
								msgbox("Bordero nr."+SEA->EA_NUMBOR+" possui titulos em processo de aprovação ou reprovados, verifique!!!", "ATENCAO")
								lRet:= .F.
							EndIf
							(cTab)->(dbClosearea())
						EndIf
						SEA->(dbSkip())
					Enddo
				Endif

				IF lRet
					dbSelectArea("SEA")
					dbSetOrder(1)
					IF dbSeek(xFilial("SEA")+MV_PAR01,.T.)
						mv_par05:= SEA->EA_PORTADO
						mv_par06:= SEA->EA_AGEDEP
						mv_par07:= SEA->EA_NUMCON
						mv_par08:= "001"
					ENDIF
				ENDIF
			ENDIF
		CASE nOpcx==2
			lRet:= C6E20VLD()
		CASE nOpcx==3
			lRet:= ExistCpo("SZL",Alltrim(UPPER(mv_par03)))
			
			/*
			If lRet .AND. SZL->ZL_BANCO <> "237"
				msgbox("Arquivo de Configuração não pertence ao Banco Bradesco!!!", "ATENCAO")
				lRet:= .F.
			EndIf
			*/

		ENDCASE

	ELSEIF nTipo==2 // Retorno

		DO CASE
		CASE nOpcx==1
			DBSELECTAREA("SZL")
			SZL->(DBSETORDER(1))
			lRet:= SZL->(DBSEEK(XFILIAL("SZL")+UPPER(Alltrim(mv_par04))))
			
			/*
			If lRet .AND. SZL->ZL_BANCO <> "237"
				msgbox("Arquivo de Configuração não pertence ao Banco Bradesco!!!", "ATENCAO")
				lRet:= .F.
			EndIf
			*/
			
			IF lRet
				aSX1	:= U_CargaSX1("AFI430")
				If Len(aSX1[2]) > 0
					mv_par03 := Space(Len(aSX1[2][4]:CX1_DEF01))
				Else
					mv_par03 := Space(12)
				EndIf
				IF U_C6E20SEL()
					mv_par03:= U_C6E20ARQ()
				ENDIF
			ENDIF

		ENDCASE

	ENDIF

Return lRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C6E20VLD
Rotina de validação na geração do arquivo remessa de pagamento
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
Static Function C6E20VLD()
	Local _aRelBord 	:= {}
	Local _PosAnt 	:= 0
	Local lRet			:= .T.
	Local _nOpc		:= 0
	local _nX
/*
_aRelBord[1] - NUMERO BORDERO
_aRelBord[2] - LOGICO DATABOR MENOR DATABASE
_aRelBord[3] - LOGICO BORDERO CONCILIADO
_aRelBord[4] - ARQ JA GERADO
_aRelBord[5] - NOME DO ARQ
*/
	dbSelectArea("SEA")
	dbSeek(xFilial("SEA")+mv_par01,.T.)
	While SEA->(!Eof()) .And. SEA->EA_NUMBOR <= mv_par02 .and. SEA->EA_FILIAL == xFilial("SEA")

		If SEA->EA_DATABOR < DDATABASE
			// Despreza borderos com a Data menor que a DataBase
			_PosAnt := ascan(_aRelBord,{|x| x[1] == SEA->EA_NUMBOR })
			If _PosAnt == 0
				AADD(_aRelBord,{SEA->EA_NUMBOR,.T.,.F.,.F.,""})
			Else
				_aRelBord[_PosAnt][2] := .T.
			EndIf

			SEA->(DbSkip())
			Loop
		EndIf


		DbSelectArea("SE2")
		DbSetOrder(1)
		If DbSeek(xFilial("SE2")+ SEA->(EA_PREFIXO+EA_NUM+EA_PARCELA+EA_TIPO+EA_FORNECE+EA_LOJA))
			While !SE2->( Eof() ) .And. SE2->E2_FILIAL == cFilial .And.;
					SE2->E2_NUMBOR>=mv_par01 .and. SE2->E2_NUMBOR <=mv_par02

				DbSelectArea("SE5")
				SE5->(DbSetOrder(7))
				IF SE5->(DBSEEK(xFILIAL("SE5")+SE2->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA)))
					IF !Empty(SE5->E5_RECONC)
						_PosAnt := ascan(_aRelBord,{|x| x[1] == SE2->E2_NUMBOR })
						If _PosAnt == 0
							AADD(_aRelBord,{SE2->E2_NUMBOR,.F.,.T.,.F.,""})
						Else
							_aRelBord[_PosAnt][3] := .T.
						EndIf
						DbSelectArea("SE2")
						SE2->(DbSkip())
						Loop
					EndIf
				EndIf

				If !Empty(SE2->E2_XPAGFOR)
					_PosAnt := ascan(_aRelBord,{|x| x[1] == SE2->E2_NUMBOR })
					If _PosAnt == 0
						AADD(_aRelBord,{SE2->E2_NUMBOR,.F.,.F.,.T.,SE2->E2_XPAGFOR})
					Else
						_aRelBord[_PosAnt][4] := .T.
					EndIf
				EndIf

				DbSelectArea("SE2")
				SE2->(DbSkip())
			EndDo
		EndIf
		DbSelectArea("SEA")
		SEA->(DbSkip())
	EndDo

	For _nX := 1 to Len(_aRelBord)
		Do Case
		Case _aRelBord[_nX,2]
			msgbox("O Bordero "+_aRelBord[_nX,1]+" não pertence a data de "+DTOC(DDATABASE)+"!!!", "ATENCAO")
			lRet:=.f.
		Case _aRelBord[_nX,3]
			msgbox("Alguns titulos do Bordero "+_aRelBord[_nX,1]+" encontram-se Conciliados!!!", "ATENCAO")
			lRet:=.f.
		Case _aRelBord[_nX,4]
			_nOpc := Aviso(OemToAnsi("Atenção"),OemToAnsi("O bordero "+_aRelBord[_nX,1]+" já foi Gerado. Deseja gerar novamente??? (")+_aRelBord[_nX,5]+")",{"Sim","Não"})
			If _nOpc == 2
				lRet:=.f.
				exit
			EndIf
		EndCase
	Next _nX

Return lRet
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} C6E20SEL
Rotina de seleção do arquivo de retorno de pagamento na consulta padrão SZLDIR
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function C6E20SEL()
	Local cTipo   := "Arquivos RET|*.RET|Arquivos TXT|*.TXT"
	Local lRet:= .T.
	Local _cArqCfg:= ""

	IF ISINCALLSTACK("FINA200")
		
		_cArqCfg:= MV_PAR05

	ELSEIF ISINCALLSTACK("FINA150") .OR. ISINCALLSTACK("FINA151")
		
		_cArqCfg:= MV_PAR03

	ELSE
		
		_cArqCfg:= MV_PAR04

	ENDIF

	IF !EMPTY(_cArqCfg)
		DbSelectArea("SZL")
		DbSetOrder(1)
		If DbSeek(xFilial("SZL")+Alltrim(UPPER(_cArqCfg)))
			cPathRet	:= /*alltrim(SZL->ZL_PATH) +*/ alltrim(cGetFile(cTipo,("Selecione o Arquivo"),,ALLTRIM(SZL->ZL_PATH),.F.,GETF_NOCHANGEDIR,.T.))
			lRet:= !Empty(cPathRet)
		Else
			MSGALERT("Arquivo "+Alltrim(UPPER(_cArqCfg))+" não encontrado no cadastro de configuração de CNAB!")
			lRet:=	.F.
		Endif
	ELSE
		MSGALERT("Informe o arquivo de configuração!")
		lRet:=	.F.
	Endif

Return lRet

//---------------------------------------------------------------------------------------
/*/{Protheus.doc}
Retorna arquivo de configuração na consulta padrão SZLRET
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function C6E20CFG()
Local _cArqCfg:= ""

//Atualiza parametros de banco, agencia, conta e subconta
IF ISINCALLSTACK("FINA200")
	
	_cArqCfg:= SZL->ZL_ARQUIVO
	
	MV_PAR06:= SZL->ZL_BANCO
	MV_PAR07:= SZL->ZL_AGENCIA
	MV_PAR08:= SZL->ZL_CONTA
	MV_PAR09:= SZL->ZL_SUBCTA

ELSEIF ISINCALLSTACK("FINA150") .OR. ISINCALLSTACK("FINA151")
	
	_cArqCfg:= SZL->ZL_ARQUIVO
	
	MV_PAR05:= SZL->ZL_BANCO
	MV_PAR06:= SZL->ZL_AGENCIA
	MV_PAR07:= SZL->ZL_CONTA
	MV_PAR08:= SZL->ZL_SUBCTA	

ELSE
	_cArqCfg:= SZL->ZL_ARQUIVO

	MV_PAR05:= SZL->ZL_BANCO
	MV_PAR06:= SZL->ZL_AGENCIA
	MV_PAR07:= SZL->ZL_CONTA
	MV_PAR08:= SZL->ZL_SUBCTA
		
ENDIF

Return(_cArqCfg)

//---------------------------------------------------------------------------------------
/*/{Protheus.doc}

Rotina de retorno do arquivo .RET na consulta padrão SZLDIR
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function C6E20ARQ()

	IF ISINCALLSTACK("U_FA420NAR")
		cPathRet:= MV_PAR04
	ENDIF

Return(cPathRet)


//---------------------------------------------------------------------------------------
/*/{Protheus.doc}
Filtro arquivo de configuração na consulta padrão SZLRET
@author  	Totvs
@since     	01/01/2015
@version  	P.11.8
@return   	Nenhum
/*/
//---------------------------------------------------------------------------------------
User Function C6E20FIL()
Local _cFiltro:= ""


//Atualiza parametros de banco, agencia, conta e subconta
IF ISINCALLSTACK("FINA200")
	_cFiltro:= "@ZL_ARQUIVO LIKE '%RET%'"
ELSEIF ISINCALLSTACK("FINA150") .OR. ISINCALLSTACK("FINA151")
	_cFiltro:= "@ZL_ARQUIVO LIKE '%REM%'"
ELSE
	_cFiltro:= "@ZL_ARQUIVO LIKE '%CPR%' OR ZL_ARQUIVO LIKE '%2PR%'"
ENDIF

Return(_cFiltro)

