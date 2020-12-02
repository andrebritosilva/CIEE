#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK02
Rotina de calculo e pagamento da bolsa auxílio
@author carlos.henrique
@since 06/11/2019
@version undefined
@type User function
/*/
User Function CJOBK02()
Local _lJob		:= GetRemoteType() == -1 // Verifica se é job
Local _cProcesso:= "CJOBK02JOB"
Local lProSPBA  := .F.
Local dGetRef   := dDataBase
Local dBkpDta	:= dDataBase

Begin Sequence

	If _lJob 
		dDataBase:= MV_PAR01  //Data do parametro do SCHEDULE
		U_CJBK02LOG(1,"Iniciando processamento via schedule.")
		U_CJBK02LOG(1,"Empresa:" + CEMPANT )
		U_CJBK02LOG(1,"Filial :" + CFILANT )
		U_CJBK02LOG(1,"Data   :" + DTOC(dDataBase) )
		lProSPBA  := .T.
	else
		DEFINE MSDIALOG oDlg TITLE "Calculo bolsa auxílio " From 000,000 to 085,280 COLORS 0, 16777215 PIXEL
		
		@ 006, 009 SAY oSay PROMPT "Data de Referência:" SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 005,084 MSGET oGet VAR dGetRef SIZE 045,011 OF oDlg COLORS 0, 16777215 PIXEL
		@ 022,093 BUTTON oButtonOK PROMPT "OK" SIZE 034,013 OF oDlg PIXEL Action(lProSPBA:= .T., oDlg:End())
		@ 022,054 BUTTON oButtonCancel PROMPT "Cancela" SIZE 034,013 OF oDlg PIXEL Action(lProSPBA:= .F., oDlg:End())
		
		ACTIVATE MSDIALOG oDlg CENTERED

		IF lProSPBA
			dDataBase:= dGetRef
		ENDIF

	Endif			

	if lProSPBA

		ZC8->(DbSetOrder(1))
		If !LockByName(_cProcesso,.T.,.T.)
			If _lJob
				U_CJBK02LOG(1,"Já existe um processamento em execução, aguarde!")	
			ELSE
				MSGINFO("Já existe um processamento em execução, aguarde! "+CRLF+" Processo: "+_cProcesso)
			Endif
			Break
		Endif

		If !_lJob
			
			//processa calculo
			FWMsgRun(,{|| CJOBK02PRC(_lJob,_cProcesso) },,"Processando calculo da bolsa auxílio, aguarde...")
			
			//processa financeiro
			//FWMsgRun(,{|| U_CJOBK03() },,"Processando pagamento da bolsa auxílio, aguarde...")
			
		Else
		
			//processa calculo
			CJOBK02PRC(_lJob,_cProcesso)

			//processa financeiro
			//U_CJOBK03()

		Endif

		UnLockByName(_cProcesso,.T.,.T.)	
	ENDIF

End Sequence	


dDataBase:= dBkpDta

Return Nil

/*/{Protheus.doc} CJBK01PR
Rotina de processamento
@author carlos.henrique
@since 14/11/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJOBK02PRC(_lJob,_cProcesso)
Local _dDataRef := If(Type("dDataBase")=="D",dDataBase,Date())
Local _cAliasFol:= GetNextAlias()
Local cGrid		:= AllTrim(SuperGetMV("CI_GRIDPBA",,"2")) //Define se calculo será em Grid   
Local _aRecFol	:= {}
Local oGrid		:= nil
Local nX		:= 0
Local lRet		:= .T.

U_CJBK02LOG(1,"Inicio Processamento "+_cProcesso)

BeginSql Alias _cAliasFol
	SELECT ZC7.R_E_C_N_O_ NREGZC7
	FROM %TABLE:ZC7% ZC7
	WHERE ZC7.ZC7_FILIAL= %xfilial:ZC7%
	AND ZC7.ZC7_STATUS IN ('2','3')
	AND ZC7.ZC7_DTPGTO=%Exp:_dDataRef%		 	
	AND ZC7.%notDel%	
	ORDER BY ZC7.R_E_C_N_O_
EndSql
//GETLastQuery()[2]
While (_cAliasFol)->(!Eof())

	AADD(_aRecFol,(_cAliasFol)->NREGZC7)

(_cAliasFol)->(dbSkip())
end
(_cAliasFol)->(DbCloseArea())


IF !EMPTY(_aRecFol)
    
    //Processamento em grid
    IF cGrid == "1" 
        
        oGrid := GridClient():New()
        
        lRet := oGrid:BatchExec("U_CJBK02AMB",{cEmpAnt,cFilAnt,""},"U_CJBK02CAL",_aRecFol)

        If !lRet .and. Empty(oGrid:aGridThreads)
			U_CJBK02LOG(1,"Nenhum Agente do GRID disponivel no Momento.")
        EndIf

        If !empty(oGrid:aErrorProc)               
            varinfo('Lista de Erro',oGrid:aErrorProc)   
        Endif   

        If !empty(oGrid:aSendProc)                 
            varinfo('Não processado',oGrid:aSendProc)   
        Endif 
	else
		For nX:= 1 to len(_aRecFol)
			STARTJOB("U_CJBK02AMB" ,GetEnvServer(),.T.,{cEmpAnt,cFilAnt,"U_CJBK02CAL("+CVALTOCHAR(_aRecFol[nX])+")"})
			//U_CJBK02AMB({cEmpAnt,cFilAnt,"U_CJBK02CAL("+CVALTOCHAR(_aRecFol[nX])+")"}) //DEBUGAR
		Next	
	endif		
else
	U_CJBK02LOG(1,"Nenhuma bolsa para calcular.")
endif

U_CJBK02LOG(1,"Fim do Processamento "+_cProcesso)

Return Nil

/*/{Protheus.doc} CJBK02AMB
Prepara ambiente GRID
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
USER Function CJBK02AMB(aParms)
Local cEmpParm:= aParms[1]	// Empresa --> cEmpAnt
Local cFilParm:= aParms[2]	// Filial  --> cFilAnt
Local cFunExec:= aParms[3]	// Rotina  ---> Apenas startjob

U_CJBK02LOG(1,"Inciando calculo da bolsa auxílio")

RpcSetType(3)
RPCSetEnv(cEmpParm,cFilParm) 

IF !EMPTY(cFunExec)
	&(cFunExec)
ENDIF

Return .T.
/*/{Protheus.doc} CJBK02CAL
Rotina de calculo da bolsa auxilio
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CJBK02CAL(nRecno)
Local _cRoteiro	 := AllTrim(SuperGetMV("CI_ROTECH",,"FOL"))
Local cError     := ""
Local bError 	 := ErrorBlock( {|e| cError := e:Description } )   
Local _dDataRef  := CTOD("")
Local _nMesRef   := 0
Local _nAnoRef	 := 0
Local _cPeriodoMA:= ""
Local _cPerg 	 := "GPEM020"
Local _cAliasTrb := ""
Local _cAliasPesq:= ""	
Local _aProcesso := {}
Local _nPos 	 := 0
Local _cSeqLan	 := ""
Local _nCount	 := 0
LOCAL _cIniLog	 := ""
LOCAL _cNumPag	 := ""
Local _cBkpMLog  := ""
Local _cBkpLCom  := ""
Private nRecZC7  := nRecno

DbSelectarea("ZC7")
ZC7->(DbGoto(nRecno))

If ZC7->(!Eof())
	If SoftLock("ZC7")

		U_CJBK02LOG(1,"Calculando bolsa auxílio: " + ZC7->ZC7_IDFOL)

		_dDataRef  	:= ZC7->ZC7_DTPGTO	//If(Type("dDataBase")=="D",dDataBase,Date())
		dDataBase	:= _dDataRef
		_nMesRef   	:= Month(_dDataRef)
		_nAnoRef	:= Year(_dDataRef)
		_cPeriodoMA := StrZero(_nMesRef,2)+StrZero(_nAnoRef,4)

		Begin transaction

			Begin Sequence

				//Valida se o padrão de períodos foi cadastrado
				RG5->(dbSetOrder(1))
				If !RG5->(dbSeek(xFilial("RG5")+ "001" ))
					_cIniLog+= "Realize o cadastro de padrão de períodos com código 001 na tabela RG5." + CRLF
				ENDIF

				//Valida se o padrão de períodos foi cadastrado
				SRY->(dbSetOrder(1))
				If !SRY->(dbSeek(xFilial("SRY")+ _cRoteiro ))
					_cIniLog+= "Roteiro de calculo "+ _cRoteiro +" não encontrado na tabela SRY." + CRLF
				ENDIF	

				IF EMPTY(_aProcesso := CJBK02RCJ(_cRoteiro,_cPeriodoMA))
					_cIniLog+= "A configuração de folha " + ALLTRIM(ZC7->ZC7_IDCFGF) + " não existe ou não possui os locais vinculados" + CRLF		
				ENDIF				

				if !EMPTY(_cIniLog)
					U_CJBK02LOG(2,"Falta configuração para inicio do processamento","3",_cIniLog)
					Break
				endif	
				
				For _nPos := 1 To Len(_aProcesso)
				
					RCJ->(dbSetOrder(1))
					IF !RCJ->(dbSeek(xFilial("RCJ")+ _aProcesso[_nPos][1] ))
						U_CJBK02LOG(2,"Processo "+ _aProcesso[_nPos][1] +" não localizado","3")
						Break		
					ENDIF				

					_cNumPag:= CJBK02NPG(_cPeriodoMA,RCJ->RCJ_CODIGO,.F.)	

					//Tratamento para geração de períodos da folha
					IF !CJBK02PER(_cRoteiro,RCJ->RCJ_CODIGO,_dDataRef,_cNumPag)
						U_CJBK02LOG(2,"Período "+ANOMES(_dDataRef)+" não localizado na tabela RCH","3",;
									"Período: "+ANOMES(_dDataRef) + CRLF+;
									"Roteiro: "+ _cRoteiro + CRLF+;
									"Numero pagamento: "+_cNumPag)	
						Break							
					ENDIF

					//verificar se o periodo esta ativo
					If RCH->RCH_PERSEL <> "1"
						//Caso não esteja ativo ativar automaticamente
						AtivaRCH(RCH->(RECNO()),_cPeriodoMA)	
					Endif			

					// Consulta analitico da folha
					_cPeriodo := RCH->RCH_PER				
					_cAliasTrb:= GetNextAlias()

					BeginSql Alias _cAliasTrb
						SELECT ZC8.R_E_C_N_O_ NREGZC8,
							SRV.R_E_C_N_O_ NREGSRV,
							SRA.R_E_C_N_O_ NREGSRA
						FROM %TABLE:ZC8% ZC8			
						LEFT JOIN %TABLE:SRA% SRA ON
								SRA.RA_FILIAL  	= %xfilial:SRA%
							AND SRA.RA_XID		= ZC8.ZC8_NUMTCE
							AND SRA.RA_PROCES   = %Exp:_aProcesso[_nPos][1]% 
							AND SRA.%notDel%
						LEFT JOIN %TABLE:SRV% SRV ON
								SRV.RV_FILIAL  	= %xfilial:SRV%
							AND	SRV.RV_XTPCAI 	= ZC8.ZC8_TPKAI
							AND SRV.%notDel%
						WHERE ZC8.ZC8_IDFOL   = %Exp:ZC7->ZC7_IDFOL% 
							AND ZC8_TPKAI!=''
							AND ZC8_VLPAG > 0 
							AND ZC8.%notDel%
						ORDER BY ZC8.ZC8_IDFOL, ZC8.ZC8_NUMTCE
					EndSql
					
					//GETLastQuery()[2]

					
					While (_cAliasTrb)->(!Eof())

						ZC8->(DbGoto((_cAliasTrb)->NREGZC8))
						SRV->(DbGoto((_cAliasTrb)->NREGSRV))
						SRA->(DbGoto((_cAliasTrb)->NREGSRA))					

						//Verificar se tem verba
						If (_cAliasTrb)->NREGSRV == 0
							U_CJBK02LOG(2,"Tipo Kairós não relacionado a uma verba SRV.","3",;
										"Id SRA: " +ZC8->ZC8_NUMTCE + CRLF +; 
										"Tipo Kairós: " +ZC8->ZC8_TPKAI)
							(_cAliasTrb)->(DbSkip())
							loop	
						Endif

						//Verificar funcionario
						If (_cAliasTrb)->NREGSRA == 0
							U_CJBK02LOG(2,"Id não relacionado na tabela SRA.","3",;
										"Id Kairós: " +ZC8->ZC8_NUMTCE)
							(_cAliasTrb)->(DbSkip())
							loop	
						Endif	
						
						_cAliasPesq	:= GetNextAlias()

						BeginSql Alias _cAliasPesq
							SELECT ISNULL(MAX(RGB.RGB_SEQ),"0") NSEQRGB
							FROM %TABLE:RGB% RGB
							WHERE 	RGB.RGB_FILIAL 	= %xfilial:RGB%
								AND RGB.RGB_MAT		= %Exp:SRA->RA_MAT%  
								AND RGB.RGB_PD		= %Exp:SRV->RV_COD%
								AND RGB.RGB_PERIOD	= %Exp:_cPeriodo%
								AND RGB.RGB_SEMANA	= %Exp:_cNumPag%
								AND RGB.%notDel%
						EndSql

						_cSeqLan	:= SOMA1( (_cAliasPesq)->NSEQRGB)

						RECLOCK("RGB",.T.)
						RGB->RGB_FILIAL := SRA->RA_FILIAL
						RGB->RGB_MAT 	:= SRA->RA_MAT
						RGB->RGB_ROTEIR := _cRoteiro
						RGB->RGB_PERIOD := _cPeriodo 
						RGB->RGB_SEMANA := _cNumPag
						RGB->RGB_PD     := SRV->RV_COD
						RGB->RGB_TIPO1  := SRV->RV_TIPO
						RGB->RGB_VALOR  := ZC8->ZC8_VLPAG
						RGB->RGB_DTREF  := _dDataRef
						RGB->RGB_CC     := SRA->RA_CC
						RGB->RGB_TIPO2  := "I"
						RGB->RGB_PROCES := SRA->RA_PROCES
						RGB->RGB_SEQ    := _cSeqLan
						RGB->RGB_CODFUN := SRA->RA_CODFUNC
						RGB->RGB_DEPTO  := SRA->RA_DEPTO
						RGB->RGB_XIDFOL := ZC7->ZC7_IDFOL
						RGB->RGB_XIDCNT := ZC7->ZC7_IDCNTT
						RGB->RGB_XIDLOC := ZC7->ZC7_IDLOCC
						RGB->(MsUnLock())

						(_cAliasPesq)->(DbCloseArea())

					(_cAliasTrb)->(DbSkip())
					End

					(_cAliasTRB)->(DbCloseArea())

					//Realizar o calculo
					SX1->(DbSetOrder(1))

					//Atualizar o Grupo de Pergunta para garantir que calcule conforme o processado
					For _nCount := 1 To 4
						If SX1->(DbSeek(PADR(_cPerg,LEN(SX1->X1_GRUPO))+StrZero(_nCount,2))) .and. SX1->(Reclock("SX1", .F.)) 
							If _nCount == 1 
								SX1->X1_CNT01 := _aProcesso[_nPos,1]
							ElseIf _nCount == 2 
								SX1->X1_CNT01 := _aProcesso[_nPos,2]
							ElseIf _nCount == 3 
								SX1->X1_CNT01 := _aProcesso[_nPos,3]
							Endif	
							SX1->(MsUnlock())
						Endif
					Next

					//Calcula folha
					GPEM020(.T., _aProcesso[_nPos,1], _aProcesso[_nPos,2], "")

					//Fecha o período
					_cNumPag:= CJBK02NPG(_cPeriodoMA,RCJ->RCJ_CODIGO,.T.)

					//Tratamento para geração de períodos da folha
					IF !CJBK02PER(_cRoteiro,RCJ->RCJ_CODIGO,_dDataRef,_cNumPag)
						U_CJBK02LOG(2,"Período "+ANOMES(_dDataRef)+" não localizado na tabela RCH","3",;
									"Período: "+ANOMES(_dDataRef) + CRLF+;
									"Roteiro: "+ _cRoteiro + CRLF+;
									"Numero pagamento: "+_cNumPag)							
						Break
					ENDIF

					U_CJBK02LOG(1,"Fechando bolsa auxílio: " + ZC7->ZC7_IDFOL)

					GPEM120(_aProcesso[_nPos,1], _aProcesso[_nPos,2])

					//DELETA VERBAS MES ANTERIOR  ==> Validar com time de RH se precisa manter
					IF TCSQLEXEC("DELETE "+RETSQLNAME("RGB")+" WHERE RGB_XIDFOL='"+ZC7->ZC7_IDFOL+"' AND D_E_L_E_T_=''"+;
								" AND RGB_XIDFOL IN (SELECT RD_XIDFOL FROM "+ RETSQLNAME("SRD") +" WHERE RD_XIDFOL='"+ZC7->ZC7_IDFOL+"' AND D_E_L_E_T_='')") < 0
						U_CJBK02LOG(1,TCSQLERROR())
					ENDIF			
					
					//Exclui o novo periodo
					CJBK02DPE(_cRoteiro,RCJ->RCJ_CODIGO,_dDataRef,_cNumPag)

					U_CJBK02LOG(2,"Processamento finalizado com sucesso","4","")				
					
				Next
			
			Recover

				_cBkpMLog  := ZC7->ZC7_MSGLOG
				_cBkpLCom  := ZC7->ZC7_LOGCOM			

				DisarmTransaction()
				ErrorBlock( bError )		

				IF !EMPTY(cError)
				
					U_CJBK02LOG(2,"Falha no calculo","3",cError)
				
				ELSEIF EMPTY(cError) .AND. !EMPTY(_cBkpMLog)

					U_CJBK02LOG(2,_cBkpMLog,"3",_cBkpLCom)					

				ENDIF	

			End Begin

		End transaction

	ELSE
		U_CJBK02LOG(1,"Não foi possivel travar o registro da folha: " + ZC7->ZC7_IDFOL)	
	ENDIF
ELSE
	U_CJBK02LOG(1,"Não foi possivel posicionar o recno: " + CVALTOCHAR(nRecno) + " da tabela ZC7.")	
ENDIF

Return
/*/{Protheus.doc} CJBK02LOG
Rotina de gravação do log
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CJBK02LOG(nTpLog,cMsgLog,cStatus,cLogCom)
default cStatus:= ""
default cLogCom:= ""

Do Case
Case nTpLog == 1 //Exibe log em tela ou console

	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK02] " + cMsgLog)

CASE nTpLog == 2 //Grava log na tabela ZC7 posicionada

	DbSelectarea("ZC7")
	ZC7->(DbGoto(nRecZC7))

	RECLOCK("ZC7",.F.)
	ZC7->ZC7_MSGLOG:= cMsgLog
	ZC7->ZC7_STATUS:= cStatus
	ZC7->ZC7_LOGCOM:= cLogCom	
	MSUNLOCK()

Otherwise
	CONOUT(cMsgLog)	
EndCase CASE

return

/*/{Protheus.doc} AtivaRCH
//Deixar ativo o periodo para receber a integração
@author denilso.almeida
@since 28/11/2019
@version 1.0
@return ${return}, ${return_description}
@param _nRegRCH, , descricao
@type function
/*/
Static Function AtivaRCH(_nRegRCH,_cPeriodoMA)
Local _cAliasRCH := GetNextAlias()
Local _cAnoCompet:= Substr(_cPeriodoMA,3,4)

//localizar a competencia referente ao ano para verificar competencia ativa
BeginSql Alias _cAliasRCH
	SELECT ISNULL(RCH.R_E_C_N_O_,"0") NREGRCH
	FROM %TABLE:RCH% RCH
	WHERE 	RCH.RCH_FILIAL 	= %xfilial:RCH%
		AND SUBSTRING(RCH.RCH_PER,1,4) 	= %Exp:_cAnoCompet%
		AND RCH.RCH_PERSEL= '1'			 	
		AND RCH.%notDel%
EndSql

//caso localize deixar o periodo inativo = 2 
If  (_cAliasRCH)->NREGRCH > 0
	RCH->(DbGoto((_cAliasRCH)->NREGRCH))
	RECLOCK("RCH",.F.)
	RCH->RCH_PERSEL := "2"
	RCH->(MsUnLock())    	
Endif

(_cAliasRCH)->(DbCloseArea())

RCH->(DbGoto(_nRegRCH))
RECLOCK("RCH",.F.)
RCH->RCH_PERSEL := "1"  //ativo
RCH->(MsUnLock())    	

Return

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function Scheddef()
Local aParam := {"P","CJOBK02","",{},""}    
Return aParam
/*/{Protheus.doc} CJBK02PER
Gera periodo para calculo
@author carlos.henrique
@since 30/01/2019
@version undefined
@type function
/*/
Static function CJBK02PER(_cRoteiro,_cProcesso,_dDataRef,_cNumPag)
Local cBkpMdl := trim(cModulo)
Local lRet := .T.
Local lLock:= .F.
Local cKey := ""

SetModulo("SIGAGPE", "GPE" )

RGA->(dbSetOrder(1))
lLock:= !RGA->(dbSeek(xFilial("RGA") + _cProcesso + _cRoteiro ))

RGA->(RecLock("RGA",lLock))
RGA->RGA_FILIAL := xFilial("RGA")
RGA->RGA_PROCES := _cProcesso
RGA->RGA_CALCUL := _cRoteiro
RGA->RGA_PDPERI := "001"
RGA->RGA_DTINIC := FirstDate(_dDataRef)
RGA->RGA_MODULO := "GPE"
RGA->(MsUnLock()) 

RG6->(dbSetOrder(1))
lLock:= !RG6->(dbSeek(xFilial("RG6") + RGA->RGA_PDPERI + STRZERO(MONTH(_dDataRef),2) + _cNumPag ))

RG6->(RecLock("RG6",lLock))
RG6->RG6_FILIAL := xFilial("RG6")
RG6->RG6_PDPERI := RGA->RGA_PDPERI
RG6->RG6_CODIGO := STRZERO(MONTH(_dDataRef),2)
RG6->RG6_NUMPAG := _cNumPag
RG6->RG6_DIAPER := DAY(LastDate(_dDataRef))  
RG6->(MsUnLock()) 

cKey :=  xFilial("RCH") + _cProcesso + ANOMES(_dDataRef) + _cNumPag + _cRoteiro

RCH->(dbSetOrder(1))	
IF !RCH->(dbSeek(cKey))
	
	//Gera periodo	
	U_CGPEM23(_cProcesso,_cRoteiro,"2",.T.,_cNumPag) 

	cKey :=  xFilial("RCH") + _cProcesso + ANOMES(_dDataRef) + _cNumPag 
	//Ajusta módulo na tabela RCF
	RCF->(dbSetOrder(3))
	IF RCF->(dbSeek(cKey))
		RCF->(RecLock("RCF",.F.))
		RCF->RCF_MODULO := "GPE"
		RCF->(MsUnLock())
	ENDIF
ENDIF

cKey :=  xFilial("RCH") + _cProcesso + ANOMES(_dDataRef) + _cNumPag + _cRoteiro

RCH->(dbSetOrder(1))	
IF !RCH->(dbSeek(cKey))
	lRet := .F.	
endif

SetModulo("SIGA"+cBkpMdl, cBkpMdl)

Return lRet
/*/{Protheus.doc} CJBK02DPE
Exclui novo perído criado para fechamento
@author carlos.henrique
@since 30/01/2019
@version undefined
@type function
/*/
Static function CJBK02DPE(_cRoteiro,_cProcesso,_dDataRef,_cNumPag)
Local cPerCal:= ANOMES(_dDataRef)
Local cKey:= ""

RGA->(dbSetOrder(1))
IF RGA->(dbSeek(xFilial("RGA") + _cProcesso + _cRoteiro ))
	RG6->(dbSetOrder(1))
	If RG6->(dbSeek(xFilial("RG6") + RGA->RGA_PDPERI + STRZERO(MONTH(_dDataRef),2) + _cNumPag ))
		RG6->(RecLock("RG6",.F.))
		RG6->(DBDELETE())
		RG6->(MsUnLock()) 
	endif
endif

cKey :=  xFilial("RCH") + _cProcesso + cPerCal + _cNumPag + _cRoteiro

RCH->(dbSetOrder(1))	
IF RCH->(dbSeek(cKey))

	RecLock("RCH",.F.)
	RCH->(DBDELETE())
	RCH->(MsUnLock()) 

	cKey :=  xFilial("RCH") + _cProcesso + cPerCal + _cNumPag 
	RCF->(dbSetOrder(3))
	IF RCF->(dbSeek(cKey))
		RCF->(RecLock("RCF",.F.))
		RCF->(DBDELETE())
		RCF->(MsUnLock())
	ENDIF

	cKey :=  xFilial("RFQ") + _cProcesso + cPerCal + _cNumPag 
	RFQ->(dbSetOrder(1))
	IF RFQ->(dbSeek(cKey))
		RecLock("RFQ",.F.)
		RFQ->(DBDELETE())
		RFQ->(MsUnLock())
	ENDIF

ENDIF

//Ajusta persel de periodos já fechados
IF TCSQLEXEC("UPDATE "+RETSQLNAME("RCH")+" SET RCH_PERSEL='2' WHERE RCH_PER='"+cPerCal+"' AND D_E_L_E_T_=''"+;
				" AND RCH_STATUS='5'") < 0
	U_CJBK02LOG(1,TCSQLERROR())
ENDIF		

Return
/*/{Protheus.doc} CJBK02NPG
Seleciona numero de pagamento do periodo e competência
@author carlos.henrique
@since 30/01/2019
@version undefined
@type function
/*/
static function CJBK02NPG(_cPeriodoMA, _cProcesso, _lFecha)
Local _cAliasRCH := GetNextAlias()
Local _cPerRCH   := RIGHT(_cPeriodoMA ,4) + LEFT(_cPeriodoMA ,2)
Local _cNumPag   := ""
Local _nPag   	 := 0

IF _lFecha
	BeginSql Alias _cAliasRCH
		SELECT RCH_NUMPAG FROM %TABLE:RCH% RCH
		WHERE RCH_FILIAL=%xfilial:RCH%
		AND RCH_PROCES= %Exp:_cProcesso%
		AND RCH_PER= %Exp:_cPerRCH%
		AND RCH_PERSEL='1'
		AND RCH.D_E_L_E_T_=''
	EndSql
ELSE
	BeginSql Alias _cAliasRCH
		SELECT MAX(RCH_NUMPAG) AS RCH_NUMPAG FROM %TABLE:RCH% RCH
		WHERE RCH_FILIAL=%xfilial:RCH%
		AND RCH_PROCES= %Exp:_cProcesso%
		AND RCH_PER= %Exp:_cPerRCH%
		AND RCH.D_E_L_E_T_=''
	EndSql
ENDIF

_nPag:= VAL((_cAliasRCH)->RCH_NUMPAG)
_nPag++

(_cAliasRCH)->(DbCloseArea())

_cNumPag:= StrZero(_nPag,FwTamSX3("RGB_SEMANA")[1])

return _cNumPag

/*/{Protheus.doc} CJBK02RCJ
Consulta processos de acordo com a configuração de folha
@author carlos.henrique
@since 30/01/2019
@version undefined
@type function
/*/
static function CJBK02RCJ(_cRoteiro,_cPeriodoMA)
Local _cTab := GetNextAlias()
Local _aRet	:= {}

BeginSql Alias _cTab
	SELECT DISTINCT RA_PROCES FROM %TABLE:SRA% SRA
	INNER JOIN %TABLE:ZCB% ZCB ON ZCB_FILIAL='    '
		AND ZCB_IDFOLH=%Exp:ZC7->ZC7_IDCFGF%
		AND ZCB.D_E_L_E_T_=''
	WHERE RA_FILIAL=%xfilial:SRA%
	AND RA_XIDCONT=ZCB_IDCNT
	AND RA_XIDLOCT=ZCB_IDLOC
	AND RA_DEMISSA=''
	AND RA_XID IN (
		SELECT ZC8_NUMTCE FROM %TABLE:ZC8% ZC8
		WHERE ZC8_IDFOL=%Exp:ZC7->ZC7_IDFOL%
		AND ZC8.D_E_L_E_T_=''
	)
	AND SRA.D_E_L_E_T_=''
EndSql

//GETLastQuery()[2]
While (_cTab)->(!Eof())

	Aadd(_aRet, { (_cTab)->RA_PROCES, _cRoteiro, _cPeriodoMA })

(_cTab)->(dbSkip())
end
(_cTab)->(DbCloseArea())

return _aRet
