#INCLUDE "TOTVS.CH"           
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"

/*/{Protheus.doc} CJOBK03
JOB de processamento do financeiro e CNAB da bolsa auxilio ajuste
@author Carlos Henrique
@since 31/05/2019
@version undefined
@type function
@history  30/07/2020, Mario Augusto Cavenaghi - EthosX:
                      Ajustes no Layout do Relatório (ficha 164);
                      Removido variáveis fora de uso
/*/ 

User Function CJOBK03(lPensao)
	Local _lJob		:= GetRemoteType() == -1 // Verifica se é job
	Local _cProcesso:= "CJOBK03JOB"
	Local lProCNAB  := .F.
	Local dGetRef   := dDataBase
	Local dBkpDta	:= dDataBase
	DEFAULT lPensao := .F.

	Begin Sequence

		//Tratamento para gerar o financeiro após o calculo
		if IsInCallStack("U_CJOBK02")
			If !_lJob
				//Processo em tela
				FWMsgRun(,{|| CJOBK03PRC(_lJob,_cProcesso) },,"Gerando CNAB de pagamento de bolsa auxílio, aguarde...")
			Else
				//Processo em JOB
				CJOBK03PRC(_lJob,_cProcesso)
			Endif
		ELSE

			If _lJob
				dDataBase:= MV_PAR01  //Data do parametro do SCHEDULE
				U_CJBK03LOG(1,"["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK03] Iniciando processamento via schedule.")
				U_CJBK03LOG(1,"Empresa:" + CEMPANT )
				U_CJBK03LOG(1,"Filial :" + CFILANT )
				U_CJBK03LOG(1,"Data   :" + DTOC(dDataBase) )
				lProCNAB  := .T.
			else

				if IsInCallStack("U_CFINA94") //Se foi chamado pela rotina de Ordem de Pagamento
					lProCNAB := .T.
					dGetRef := dDtRefOP //variavel iniciada no fonte CFINA94
				
				ElseIf lPensao

					DEFINE MSDIALOG oDlg TITLE "CNAB Pensão " From 000,000 to 085,280 COLORS 0, 16777215 PIXEL

					@ 006, 009 SAY oSay PROMPT "Data de Pagamento:" SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
					@ 005,084 MSGET oGet VAR dGetRef SIZE 045,011 OF oDlg COLORS 0, 16777215 PIXEL
					@ 022,093 BUTTON oButtonOK PROMPT "OK" SIZE 034,013 OF oDlg PIXEL Action(lProCNAB:= .T., oDlg:End())
					@ 022,054 BUTTON oButtonCancel PROMPT "Cancela" SIZE 034,013 OF oDlg PIXEL Action(lProCNAB:= .F., oDlg:End())

					ACTIVATE MSDIALOG oDlg CENTERED

				else

					DEFINE MSDIALOG oDlg TITLE "CNAB bolsa auxílio " From 000,000 to 085,280 COLORS 0, 16777215 PIXEL

					@ 006, 009 SAY oSay PROMPT "Data de Pagamento:" SIZE 073,007 OF oDlg COLORS 0, 16777215 PIXEL
					@ 005,084 MSGET oGet VAR dGetRef SIZE 045,011 OF oDlg COLORS 0, 16777215 PIXEL
					@ 022,093 BUTTON oButtonOK PROMPT "OK" SIZE 034,013 OF oDlg PIXEL Action(lProCNAB:= .T., oDlg:End())
					@ 022,054 BUTTON oButtonCancel PROMPT "Cancela" SIZE 034,013 OF oDlg PIXEL Action(lProCNAB:= .F., oDlg:End())

					ACTIVATE MSDIALOG oDlg CENTERED

				endif

				IF lProCNAB
					dDataBase:= dGetRef
				ENDIF

			Endif

			if lProCNAB

				If !LockByName(_cProcesso,.T.,.T.)
					If _lJob
						U_CJBK03LOG(1,"["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][ "+_cProcesso+" ] Já existe um processamento em execução, aguarde!")
					Else
						MSGINFO("Já existe um processamento em execução, aguarde! "+CRLF+" Processo: "+_cProcesso)
					Endif
					Break
				Endif

				If !_lJob
					//Processo em tela
					FWMsgRun(,{|| CJOBK03PRC(_lJob,_cProcesso,lPensao) },,"Gerando CNAB de pagamento de bolsa auxílio, aguarde...")
				Else
					//Processo em JOB
					CJOBK03PRC(_lJob,_cProcesso,lPensao)
				Endif

				UnLockByName(_cProcesso,.T.,.T.)

				If _lJob
					U_CJBK03LOG(1,"["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK03] Processamento finalizado.")
				else
					if IsInCallStack("U_CFINA94") //Se foi chamado pela rotina de Cnab de inconsistencia
						msginfo("Processamento finalizado!")
					else
						//Valida se existe inconsistencia cadastral
						If VerIncons(dGetRef)
							IF MSGYESNO("Processamento finalizado! Deseja gerar o relatório de inconsistencias?", "Atencão")
								U_CFINR81(dGetRef) //Relatório de inconsistências
							endif
						ENDIF
					endif
				endif

			ENDIF

		ENDIF

	End Sequence

	dDataBase:= dBkpDta

Return Nil

/*/{Protheus.doc} VerIncons
Verifica se existe inconsistencia cadastral de funcionrios (SRA)
Utilizado a mesma lógica aplicada no relatório de inconsistencia - FONTE: CFINR81.PRW
@type  Static Function
@author Luiz Enrique
@since 15/07/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
Static Function VerIncons(dGetRef)

	Local lret:= .T.
	Local cQuery := " SELECT Count(*) As INCOSIST"

//cQuery += " RA_MAT, RA_NOME, RA_XIDCONT, RA_XIDLOCT, RD_XIDFOL, RA_BCDEPSA, RD_XOCORRE, RD_DATPGT, RA_XDEATIV,RD_XNUMTIT, RD_DATPGT "
	cQuery += " FROM "+RetSqlName("SRA")+" SRA "
	cQuery += " INNER JOIN "+RetSqlName("SRD")+" SRD ON "
	cQuery += " 	SRD.D_E_L_E_T_='' AND "
	cQuery += " 	RD_FILIAL=RA_FILIAL AND "
	cQuery += "     RD_MAT=RA_MAT AND "
	cQuery += "     RD_XIDCNT=RA_XIDCONT AND "
	cQuery += "     RD_XIDLOC=RA_XIDLOCT AND "
	cQuery += " 	RD_PD='J99' "
	cQuery += " WHERE "
	cQuery += " SRA.D_E_L_E_T_='' "
	cQuery += " AND RA_XATIVO='N' "
	cQuery += " AND RD_DATPGT BETWEEN '"+DTOS(dGetRef)+"' AND '"+DTOS(dGetRef)+"' "

	If Select("TRB1") > 0
		TRB1->(DbCloseArea())
	EndIf

	cQuery := ChangeQuery(cQuery)

	dbUseArea(.T.,'TOPCONN',TcGenQry(,,cQuery),'TRB1',.T.,.T.)

	IF TRB1->(EOF()) .Or. TRB1->INCOSIST == 0
		lret:= .f.
	ENDIF

	TRB1->(DbCloseArea())

Return lret


/*/{Protheus.doc} CJOBK03PRC
Rotina de processamento do CNAB agutinado por banco + Tratamento TJ 
@author Carlos Henrique
@since 14/11/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJOBK03PRC(_lJob,_cProcesso,lPensao)
	Local _dDataRef	:= If(Type("dDataBase")=="D",dDataBase,Date())
	Local xcMMAAAA  := Strzero(MONTH(_dDataRef),2) + Alltrim(Str(Year(_dDataRef)))
	Local _cAliasRc1:= ""
	Private _aGeraLog:= {}
	Private lGeraOP  := .F.
//Processa geração do financeiro (RC1)
	Pergunte("GPM650",.F.)

// Variaveis utilizadas para parametros      
	MV_PAR01  := Replicate(" ",FwTamSX3("RC1_FILIAL")[1])   	//  Filial De
	MV_PAR02  := Replicate("Z",FwTamSX3("RC1_FILIAL")[1])    	//  Filial Ate
	MV_PAR03  := Replicate(" ",FwTamSX3("RC1_CC")[1])  			//  Centro de Custo De
	MV_PAR04  := Replicate("Z",FwTamSX3("RC1_CC")[1])        	//  Centro de Custo Ate
	MV_PAR05  := Replicate(" ",FwTamSX3("RC1_MAT")[1])        	//  Matricula De
	MV_PAR06  := Replicate("Z",FwTamSX3("RC1_MAT")[1])       	//  Matricula Ate
	MV_PAR07  := _dDataRef        								//  Dt. Busca Pagto De
	MV_PAR08  := IIF(IsInCallStack("U_CFINA94"),LastDay(_dDataRef),_dDataRef)		//  Dt. Busca Pagto Ate
	IF IsInCallStack("U_CFINA94")
		IF _cTpCNAB="CN"
			MV_PAR09  := "100"	//  Codigo Titulo De
 			MV_PAR10  := "199"	//  Codigo Titulo Ate
		ELSE
			MV_PAR09  := "200"	//  Codigo Titulo De
			MV_PAR10  := "299"	//  Codigo Titulo Ate
		ENDIF
	ELSEIF lPensao
		MV_PAR09  := "400"		//  Codigo Titulo De
		MV_PAR10  := "400"		//  Codigo Titulo Ate	
	ELSE
		MV_PAR09  := "001"		//  Codigo Titulo De
		MV_PAR10  := "099"		//  Codigo Titulo Ate
	ENDIF
	MV_PAR11  := IIF(IsInCallStack("U_CFINA94"),date(),_dDataRef) 	//  Data de Emissao
	MV_PAR12  := xcMMAAAA      										//  Competencia
	MV_PAR13  := IIF(IsInCallStack("U_CFINA94"),date(),_dDataRef)   //  Data de vencimento

	CJBK03TIT(_lJob)

//Processa geração do CNAB de bolsa auxilio com base na RC1
	_cAliasRc1:= GetNextAlias()

	BeginSql Alias _cAliasRc1
	SELECT RC1.R_E_C_N_O_ AS RECRC1
		,RC1_XROTEI
		,RC0.RC0_XCODBA AS BANCO
		,SUBSTRING(RCC.RCC_CONTEU,24,5) AS AGENCIA
		,SUBSTRING(RCC.RCC_CONTEU,30,12) AS CONTA
		,SUBSTRING(RCC.RCC_CONTEU,50,12) AS ARQCFG
		,SUBSTRING(RCC.RCC_CONTEU,62,100) AS PATH
		,RC0_PREFIX
		,RC0_CODTIT
		,A2_NOME		
		,A2_EST
	FROM %TABLE:RC1% RC1
	JOIN %TABLE:RC0% RC0 ON RC0_FILIAL=%xfilial:RC0%
		AND RC0_CODTIT=RC1_CODTIT
		AND RC0.D_E_L_E_T_=''
	JOIN %TABLE:RCC% RCC ON
		RCC.RCC_FILIAL = %xfilial:RCC%
		AND RCC.RCC_CODIGO='S052'
		AND SUBSTRING(RCC.RCC_CONTEU,21,3)= RC0.RC0_XCODBA 
		AND RCC.D_E_L_E_T_ = ' '
	JOIN %TABLE:SA2% SA2 ON A2_FILIAL=%xfilial:SA2%
		AND A2_COD=RC1_FORNEC
		AND A2_LOJA=RC1_LOJA
		AND SA2.D_E_L_E_T_=''				 		 	
	WHERE RC1_FILIAL=%xfilial:RC1%
		AND RC1_INTEGR IN ('0','1')	 
		AND RC1.D_E_L_E_T_=''	
	ORDER BY RC1.RC1_CODTIT	
	EndSql

//GETLastQuery()[2]
	While (_cAliasRc1)->(!Eof())

		RC1->(DbGoto((_cAliasRc1)->RECRC1))
		IF RC1->(!EOF())

			if !EMPTY(RC1->RC1_XCNAB)
				FERASE(ALLTRIM(RC1->RC1_XCNAB))
			endif

			//Seta status com valor pedente
			if RC1->RC1_INTEGR == "1"
				RECLOCK("RC1",.F.)
				RC1->RC1_INTEGR:= "0"
				RC1->RC1_XMSLOG:= ""
				RC1->RC1_XLGCOM:= ""
				RC1->RC1_XIDFLG:= ""
				RC1->RC1_XCNAB := ""
				RC1->RC1_XDTINT:= CTOD("")
				MSUNLOCK()
			endif

			Pergunte("XGPEM080R1", .F.)

			MV_PAR01   := (_cAliasRc1)->RC1_XROTEI 					//  Roteiros
			// MV_PAR02        										//  Roteiros
			// MV_PAR03        										//  Roteiros
			MV_PAR04   := "        "   								//  Filial  De
			MV_PAR05   := "ZZZZZZZZ"   								//  Filial  Ate
			MV_PAR06   := "         "     							//  Centro de Custo De
			MV_PAR07   := "ZZZZZZZZZ"     							//  Centro de Custo Ate
			MV_PAR08   := "        "  								//  Banco /Agencia De
			MV_PAR09   := "ZZZZZZZZ"  								//  Banco /Agencia Ate
			MV_PAR10   := "      "   								//  Matricula De
			MV_PAR11   := "ZZZZZZ"     								//  Matricula Ate
			MV_PAR12   := "                              "     		//  Nome De
			MV_PAR13   := "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"     		//  Nome Ate
			MV_PAR14   := "            "  							//  Conta Corrente De
			MV_PAR15   := "ZZZZZZZZZZZZ"  							//  Conta Corrente Ate
			MV_PAR16   := " ADFT"        							//  Situacao
			MV_PAR17   := 2     									//  Layout  cnab modelo 2
			MV_PAR18   := (_cAliasRc1)->ARQCFG     					//  Arquivo de configuracao
			MV_PAR19   := (_cAliasRc1)->PATH               			//  nome do arquivo de saida
			MV_PAR20   := _dDataRef									//  data de credito
			
			/*IF lPensao
				MV_PAR21   := _dDataRef       						//  Data de Pagamento De
			ELSE
				MV_PAR21   := _dDataRef-1       					//  Data de Pagamento De
			ENDIF*/	

			MV_PAR21   := _dDataRef 								//Removido o if anterior pois esta impactando no update do campo RD_XNUMDOC -  CARD243
			
			MV_PAR22   := _dDataRef     							//  Data de Pagamento Ate
			MV_PAR23   := "ACDEGHIJMPST***"    						//  Categorias

			IF lPensao
				MV_PAR24   := 2     								//  Imprimir 1-Funcionarios 2-Beneficiarias 3-Ambos
			Else
				MV_PAR24   := 1     								//  Imprimir 1-Funcionarios 2-Beneficiarias 3-Ambos
			endif

			MV_PAR25   := _dDataRef     							//  Data de Referencia
			MV_PAR26   := "*"     									//  Selecao de Processos
			MV_PAR27   := ""       									//  Selecao de Processos
			MV_PAR28   := " "     									//  Numero do Pedido     -- SUBSTITUIDO PELO NUMERO DO PEDIDO
			MV_PAR29   := 2     									//  Linha Vazia no Fim do Arquivo 1=Sim 2=Nao
			MV_PAR30   := AvKey((_cAliasRc1)->BANCO,"EE_CODIGO")    //  Processar Banco
			MV_PAR31   := AvKey((_cAliasRc1)->AGENCIA,"EE_AGENCIA") //  Agencia
			MV_PAR32   := AvKey((_cAliasRc1)->CONTA,"EE_CONTA")     //  Conta
			MV_PAR33   := 3   										//  Gerar Conta Tipo   1=Conta corrente 2=Conta Poupanca 3=Ambas
			
			IF Alltrim((_cAliasRc1)->BANCO) == "237"
				if (_cAliasRc1)->RC0_CODTIT == "015"
					MV_PAR34   := 1			    						//  DOC Outros Bancos  1=Sim 2=Não
				else
					MV_PAR34   := 2			    						//  DOC Outros Bancos  1=Sim 2=Não
				endif
			ELSE
				MV_PAR34   := 2			    						//  DOC Outros Bancos  1=Sim 2=Não
			ENDIF	

			MV_PAR35   := 1											//  Validar Cta Bancarias R$ 0.01?  1=Nao  2=Sim
			MV_PAR36   := ctod("")									//  Data de admissao de
			MV_PAR37   := ctod("")									//  Data de admissao Fim
			MV_PAR38   := 1          								//  Cnab Exclusivo para cliente especifico ? 1= Não, 2=Sim
			lGeraOP    := IIF(ALLTRIM((_cAliasRc1)->RC0_CODTIT)=="006",.T.,.F.)
			U_CGPER04(.T.)

			//Integração fluig será realizado após a liberação de pagamento
		/*
			if RC1->RC1_INTEGR != "2"
			//Realiza integração com Fluig
			U_CJBK03FL({{.T.,RC1->RC1_CODTIT,ALLTRIM(RC1->RC1_DESCRI),(_cAliasRc1)->RC0_PREFIX,RC1->RC1_NUMTIT,;
						RC1->RC1_TIPO,RC1->RC1_VALOR,RC1->RC1_EMISSA,RC1->RC1_VENREA,;
						RC1->RC1_NATURE,RC1->RC1_FORNEC,RC1->RC1_LOJA,(_cAliasRc1)->A2_NOME,;
						(_cAliasRc1)->A2_EST,RC1->RC1_COMPET,(_cAliasRc1)->RECRC1}})			
			endif
		*/

		ENDIF

		(_cAliasRc1)->(dbSkip())
	End

	(_cAliasRc1)->(dbCloseArea())

RETURN
/*/{Protheus.doc} CJBK03FL
Monta relatório e realiza integração com Fluig
@author carlos.henrique
@since 21/02/2020
@version 1.0
@return ${return}, ${return_description}
@param aTitSt, array, descricao
@type function
/*/
User function CJBK03FL(aTitSt)
	Local aCardData	:= {}
	Local nCnta		:= 0
	Local cSeqItem 	:= ""
	Local cNomeRel	:= ""
	Local cNomeDarf := "RECOLHIMENTO_IR_PAGTO_BOLSA_AUXILIO_" + ALLTRIM(RC1->RC1_NUMTIT)
	Local cDarfDir  := "\spool\"
	Local cDirRel	:= ""
	Local cEmpInt	:= CEMPANT
	Local cFilInt	:= CFILANT
	LOCAL cMatric   := ""
	LOCAL cZAI 		:= ""
	LOCAL cRegApr	:= TRIM(SuperGetMv("CI_BOLAUX",.F.,"BOLAUX")) 	// Regra de aprovação no back Office
	Local nCntx     := 0
	Local aItens    := {}
	Local aAttach   := {}
	Local _cCCusto	:= AllTrim(SuperGetMV( "CI_CCINTRH"  ,,"241" ))
	local cRet      := ""

	Local lXpensao	:=  U_TITPENSAO()	//Verifica se o Titulo é de Pagamento de Pensão

	Private cPictVrl:= PESQPICT("RC1","RC1_VALOR")
	Private oFlg	:= CINTFLG():New(.T.)

	If !lXpensao
		cNomeDarf := "RECOLHIMENTO_IR_PAGTO_BOLSA_AUXILIO_" + ALLTRIM(RC1->RC1_NUMTIT)
	Else
		cNomeDarf := "RECOLHIMENTO_IR_PAGTO_PENSAO_" + ALLTRIM(RC1->RC1_NUMTIT)
	Endif

	For nCnta:=1 to Len(aTitSt)

		RC1->(DBGOTO(aTitSt[nCnta][16]))	

		IF aTitSt[nCnta][1] .and. RC1->(!EOF())

			lXpensao:=  U_TITPENSAO()	//Verifica se o Titulo é de Pagamento de Pensão

			//Seta matricula de acordo com login de rede
			IF oFlg:setUserId(,,alltrim(RC1->RC1_XLREDE))

				cMatric:= oFlg:UserId
				cZAI:= GetNextAlias()

				BeginSql Alias cZAI
				SELECT DISTINCT ZAI_GRUPO, ZAH_DESCRI FROM %TABLE:ZAI% ZAI 
				INNER JOIN %TABLE:ZAH% ZAH ON ZAH_CODIGO=ZAI_GRUPO 
					AND ZAI_REGRA=%exp:cRegApr%
				WHERE ZAI_MAT = %exp:trim(cMatric)% 
				AND ZAI.D_E_L_E_T_ = ' '
				EndSql

				(cZAI)->(dbSelectArea((cZAI)))
				(cZAI)->(dbGoTop())
				IF (cZAI)->(!EOF())

					If !lXpensao
						cNomeRel:= "SINTETICO_PAGAMENTO_DE_BOLSA_AUXILIO_" + ALLTRIM(aTitSt[nCnta][5])
					Else
						cNomeRel:= "SINTETICO_PAGAMENTO_DE_PENSAO_" + ALLTRIM(aTitSt[nCnta][5])
					Endif

					aAdd(aCardData,{"txtMatSolicitante"	, oFlg:UserId 		})
					aAdd(aCardData,{"txtDataSolicitacao", DTOC(DATE()) 	})

					aAdd(aCardData,{"txtCodCR"			, oFlg:CodCR 		})
					aAdd(aCardData,{"txtDescricaoCR"	, oFlg:DesCR 		})

					aAdd(aCardData,{"txtRegraAprovacao"	, cRegApr 		})
					aAdd(aCardData,{"txtCodGrpApr"		, TRIM((cZAI)->ZAI_GRUPO) })
					aAdd(aCardData,{"txtEmpresa"		, cEmpInt		})
					aAdd(aCardData,{"txtFilial"			, cFilInt   	})
					aAdd(aCardData,{"txtEmpGpe"			, cEmpAnt		})
					aAdd(aCardData,{"txtFilGpe"			, cFilAnt   	})

					aAdd(aCardData,{"txtRamal"			, ""   		})

					aAdd(aCardData,{"txtCompetencia"	, LEFT(aTitSt[nCnta][15],2)+"/"+RIGHT(aTitSt[nCnta][15],4) })
					aAdd(aCardData,{"txtProcesso"		, aTitSt[nCnta][2] })
					aAdd(aCardData,{"txtDescProc"		, aTitSt[nCnta][3] })

					aAdd(aCardData,{"txtNumTitulo"		, aTitSt[nCnta][5] })
					aAdd(aCardData,{"txtTipoTitulo"		, aTitSt[nCnta][6] })
					aAdd(aCardData,{"txtCodFilial"		, cFilAnt })
					aAdd(aCardData,{"txtNomeFilial"		, FWFilialName(cEmpAnt,cFilAnt,2) })

					aAdd(aCardData,{"txtPrefixo"		, aTitSt[nCnta][4] })
					aAdd(aCardData,{"txtDataEmissao"	, DTOC(aTitSt[nCnta][8]) })
					aAdd(aCardData,{"txtDataVenc"		, DTOC(aTitSt[nCnta][9]) })
					aAdd(aCardData,{"txtNatureza"		, aTitSt[nCnta][10] })
					If !lXpensao
						aAdd(aCardData,{"txtHisFin"		, "PAGAMENTO DE BOLSA AUXÍLIO - " + DTOC(aTitSt[nCnta][9]) })
					Else
						aAdd(aCardData,{"txtHisFin"		, "PAGAMENTO DE PENSAO - " + DTOC(aTitSt[nCnta][9]) })
					Endif
					aAdd(aCardData,{"txtCodFornecedor"	, aTitSt[nCnta][11] })
					aAdd(aCardData,{"txtLojaFornecedor"	, aTitSt[nCnta][12] })
					aAdd(aCardData,{"txtNomeFornecedor"	, aTitSt[nCnta][13] })
					aAdd(aCardData,{"txtUFFornecedor"	, aTitSt[nCnta][14] })

					DBSELECTAREA("RC0")
					RC0->(DBSETORDER(1))
					RC0->(DBSEEK(XFILIAL("RC0")+aTitSt[nCnta][2]))

					IF CJBK03RE(aTitSt[nCnta][5],aTitSt[nCnta][3],aTitSt[nCnta][9],@cNomeRel,@cDirRel,aTitSt[nCnta][6],aTitSt[nCnta][2])

						If RC1->RC1_NATUREZ = "IRF"

							aCardData := {}

							aAdd(aCardData,{"txtMatSolicitante"	, oFlg:UserId 		})
							aAdd(aCardData,{"txtDataSolicitacao", DTOC(DATE()) 	})

							aAdd(aCardData,{"txtCodCR"			, oFlg:CodCR 		})
							aAdd(aCardData,{"txtDescricaoCR"	, oFlg:DesCR 		})

							aAdd(aCardData,{"txtRegraAprovacao"	, cRegApr 		})
							aAdd(aCardData,{"txtCodGrpApr"		, TRIM((cZAI)->ZAI_GRUPO) })
							aAdd(aCardData,{"txtEmpresa"		, cEmpInt		})
							aAdd(aCardData,{"txtFilial"			, cFilInt   	})
							aAdd(aCardData,{"txtEmpGpe"			, cEmpAnt		})
							aAdd(aCardData,{"txtFilGpe"			, cFilAnt   	})

							aAdd(aCardData,{"txtRamal"			, ""   		})

							aAdd(aCardData,{"txtCompetencia"	, LEFT(aTitSt[nCnta][15],2)+"/"+RIGHT(aTitSt[nCnta][15],4) })
							aAdd(aCardData,{"txtProcesso"		, aTitSt[nCnta][2] })
							aAdd(aCardData,{"txtDescProc"		, aTitSt[nCnta][3] })

							aAdd(aCardData,{"txtNumTitulo"		, aTitSt[nCnta][5] })
							aAdd(aCardData,{"txtTipoTitulo"		, aTitSt[nCnta][6] })
							aAdd(aCardData,{"txtCodFilial"		, cFilAnt })
							aAdd(aCardData,{"txtNomeFilial"		, FWFilialName(cEmpAnt,cFilAnt,2) })

							aAdd(aCardData,{"txtPrefixo"		, aTitSt[nCnta][4] })
							aAdd(aCardData,{"txtDataEmissao"	, DTOC(aTitSt[nCnta][8]) })
							aAdd(aCardData,{"txtDataVenc"		, DTOC(aTitSt[nCnta][9]) })
							aAdd(aCardData,{"txtNatureza"		, aTitSt[nCnta][10] })
							If !lXpensao
								aAdd(aCardData,{"txtHisFin"		, "RECOLHIMENTO DE IR PAGTO. BOLSA AUXILIO - " + Alltrim(RC1->RC1_COMPET) })
							Else
								aAdd(aCardData,{"txtHisFin"		, "RECOLHIMENTO DE IR PAGTO. PENSAO - " + Alltrim(RC1->RC1_COMPET) })
							Endif
							aAdd(aCardData,{"txtCodFornecedor"	, aTitSt[nCnta][11] })
							aAdd(aCardData,{"txtLojaFornecedor"	, aTitSt[nCnta][12] })
							aAdd(aCardData,{"txtNomeFornecedor"	, aTitSt[nCnta][13] })
							aAdd(aCardData,{"txtUFFornecedor"	, aTitSt[nCnta][14] })

							U_CFINR085(cNomeDarf,cDarfDir,.F.)

							cNomeDarf := cNomeDarf + ".pdf"
							cDarfDir  := cDarfDir + cNomeDarf

							aAttach := {{cNomeRel,cDirRel},{cNomeDarf,cDarfDir}}

						Else

							aAttach := {{cNomeRel,cDirRel}}

						EndIf

						aItens:= {}

						AADD(aItens,{RC0->RC0_XCOD,;
							POSICIONE("SB1",1,XFILIAL("SB1")+RC0->RC0_XCOD,"B1_DESC"),;
							aTitSt[nCnta][7],;
							_cCCusto})

						For nCntx:= 1 TO LEN(aItens)
							cSeqItem:= CVALTOCHAR(nCntx)
							aAdd(aCardData,{"txtSeqItem___"+cSeqItem			, STRZERO(nCntx,4) })
							aAdd(aCardData,{"txtCodProduto___"+cSeqItem			, aItens[nCntx][1] })
							aAdd(aCardData,{"txtDscProduto___"+cSeqItem			, aItens[nCntx][2] })
							aAdd(aCardData,{"txtQuantideItem___"+cSeqItem		, '1,00' })
							aAdd(aCardData,{"txtValorUnitarioItem___"+cSeqItem	, TRANSFORM(aItens[nCntx][3],cPictVrl) })
							aAdd(aCardData,{"txtValorTotalItem___"+cSeqItem		, TRANSFORM(aItens[nCntx][3],cPictVrl) })
							aAdd(aCardData,{"dsCRDesp___"+cSeqItem				, aItens[nCntx][4] })
						NEXT

						aAdd(aCardData,{"txtTotalGeral"		, TRANSFORM(aTitSt[nCnta][7],cPictVrl) })

						IF oFlg:startprocess("WF_BolsaAuxilio",;	// ProcessId
							"18",;						// NextTask
							{oFlg:UserId},;
								"Inicio da aprovação: "+aTitSt[nCnta][3],;
								oFlg:UserId,;
								.T.,;
								aAttach,;
								aCardData)

							U_CJBK03LOG(2,"Integração realizada com sucesso!!","2","",oFlg:IdSol)
						ELSE
							U_CJBK03LOG(2,"Erro na integração com Fluig","1",oFlg:Error)
							cRet := "Erro na integração com Fluig"
						ENDIF
					ELSE
						U_CJBK03LOG(2,"Não foi possivel gerar o relatório analitico!!","1")
						cRet := "Não foi possivel gerar o relatório analitico!!"
					Endif
				ELSE
					U_CJBK03LOG(2,"Nenhum grupo encontrado para o login "+cMatric,"1")
					cRet := "Nenhum grupo encontrado para o login "+cMatric
				ENDIF
				(cZAI)->(dbCloseArea())
			ELSE
				U_CJBK03LOG(2,"Não foi possivel setar o login de rede "+alltrim(RC1->RC1_XLREDE),"1")
				cRet := "Não foi possivel setar o login de rede "+alltrim(RC1->RC1_XLREDE)
			Endif
		Endif
	NEXT

	FreeObj(oFlg)

Return


/*/{Protheus.doc} CJBK03RE
Rotina de impressão do relatório analitico.
@author carlos.henrique
@since 01/02/2019
@version undefined
@param cNumTit, characters, descricao
@param cDescr, characters, descricao
@param dDtaPag, date, descricao
@param cNomeRel, characters, descricao
@param cDirRel, characters, descricao
@param cPrefixo, characters, descricao
@param cCodTit, characters, descricao
@type function
@history  30/07/2020, Ajuste de layout
/*/
Static function CJBK03RE(cNumTit,cDescr,dDtaPag,cNomeRel,cDirRel,cTipoTit,cCodTit)

	Local lXpensao	:=  U_TITPENSAO()	//Verifica se o Titulo é de Pagamento de Pensão
	Local cTipVer	:= "509"	//Codigo da Verba = IMPOSTO DE RENDA FOLHA /RESCISAO 
	Local c2TipVer	:= ""		//530 ou 554 Códigos da Verba para PENSAO ALIMENT RRA  
	local lRet      := .T.
	Local cTab		:= GetNextAlias()
	Local nTotMov	:= 0
	Local nTotGer	:= 0
	Local nOutros	:= 0
	Local cQuery    := ""
	Local cCndAnd   := ""
	//Local aRet      := {}
	//Local cNomeDirf := "GuiaRecolhimentoDARF"
	//Local cDirDarf  := cNomeDirf + ".pdf"

	Private nLin	:= 0
	Private nAtuPag	:= 1
	Private nTotPag	:= 0
	Private cLogo	:= GetSrvProfString("Startpath","")+"\LGMID"+CEMPANT+".PNG"
	Private oFnt9 	:= TFont():New('Arial',,-9,,.F.)
	Private oFntb9 	:= TFont():New('Arial',,-9,,.T.)
	Private oFntb14 := TFont():New('Arial',,-14,,.T.)
	Private oPrint	:= NIL
	Private cPictVrl:= PESQPICT("RC1","RC1_VALOR")
	Private lImpIrf := .F.

	//Tratamento para impressão do relatório de conferência do IR
	If ALLTRIM(RC1->RC1_NATURE)=='IRF'

		If RC1->RC1_INTEGR == '4'
			MSGINFO( "Título aprovado, visualização disponivel na rotina de Contas a Pagar!","Titulo aprovado" )
		EndIf

		dDataDe  := RC1->RC1_DTBUSI
		dDataAte := RC1->RC1_DTBUSF
		cNumTit  := RC1->RC1_NUMTIT

		lImpIrf := .T.

		cQuery := " SELECT "
		cQuery += "   RD_XIDFOL, "
		cQuery += "   RD_MAT, "
		cQuery += "   RD_XIDCNT, "
		cQuery += "   RD_XIDLOC, "
		cQuery += "   RD_PERIODO, "
		cQuery += "   RD_VALOR "
		cQuery += "  FROM "+ RetSqlName("SRD")+ ""
		cQuery += " WHERE RD_DATPGT BETWEEN '" + Dtos(dDataDe) + "' AND '" + Dtos(dDataAte) + "'"
		cQuery += "   AND RD_PD = '" + cTipVer + "'"
		cQuery += "   AND RD_XNUMTIT = '" + cNumTit + "' AND D_E_L_E_T_ = ' ' "
		cQuery += "   AND RD_XIDCNT NOT IN (SELECT ZCM_CODIGO FROM " + RetSqlName("ZCM") + " ZCM WHERE ZCM.D_E_L_E_T_='')"
		cQuery += " ORDER BY RD_XIDFOL,RD_MAT "
		cQuery := ChangeQuery(cQuery)
		dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTab,.T.,.T.)

		//U_CFINR082(cNumTit,cDescr,dDtaPag,cNomeRel,cDirRel,cTipoTit,cCodTit, .F.)
		//U_CFINR085(cNomeDirf,cDirRel, .F.)

	ELSE

		If !lXpensao	//Titulo tipo Bolsa Auxilio
			cTipVer	:= "J99"
			c2TipVer:= "J99"
		Else			//Titulo tipo Pensão
			cTipVer	:= "554"
			c2TipVer:= "530"
		Endif

		cCodBanco:= RC0->RC0_XCODBA 
//		cBradesco:= RC0->RC0_XCODBA 

		RC0->(DbSetOrder(1))
		RC0->(dbSeek(xFilial("RC0") + RC1->RC1_CODTIT))
//		If RC0->(dbSeek(xFilial("RC0") + RC1->RC1_CODTIT))
//			If !Alltrim(RC0->RC0_XCODBA) $ "237|341|001|033|104"
//				cDescr:= "BANCO BRADESCO S/A"
//				cBradesco:= '237'
//			Endif
//		ENDIF

		if RC0->RC0_XCODBA == "237"
			if RC0->RC0_CODTIT == "015"
				cDescr  := "BANCO BRADESCO S/A"
				cCndAnd := "  AND LEFT(RA_BCDEPSA,3) NOT IN ('237','341','001','033','104')"
			else
				cDescr  := "BANCO BRADESCO S/A"
				If !lXpensao
					cCndAnd := "  AND LEFT(RA_BCDEPSA,3) = '" + RC0->RC0_XCODBA + "'"
				Endif	
			endif

		else
			cCndAnd := "  AND LEFT(RA_BCDEPSA,3) = '" + RC0->RC0_XCODBA + "'"
		endif
		cCndAnd := "%" + cCndAnd + "%"

		BeginSql Alias cTab
			%NOPARSER%
			SELECT DISTINCT LEFT(ZC7_COMPET,2) +'/'+ RIGHT(ZC7_COMPET,4) AS COMPETENCIA
				,RTRIM(SRD.RD_XIDCNT)+'*'+ RTRIM(SRD.RD_XIDLOC)+'*'+ SRD.RD_XIDFOL AS CONVENIO
				,ZC1_RAZSOC AS DESCCONV,
				COUNT(TBQTDEBOLSA.MATRICULA) AS  QTDEBOLSA ,
				SUM(TBTOTALBOLSA.RD_VALOR) AS  TOTALBOLSA ,
				ISNULL(SUM(TBTOTALAUXTRANSP.RD_VALOR),0) AS TOTALAUXTRANSP ,
				ISNULL(SUM(TBVALORIRRF.RD_VALOR),0) AS VALORIRRF ,
				ISNULL( SUM(TBVALORPENSAO.RD_VALOR),0 ) AS VALORPENSAO ,
				ISNULL( SUM(TBQTDEBOLSA.RD_VALOR),0 ) AS  LIQUIDOAPAGAR 
			FROM %table:SRD% SRD

				INNER JOIN %table:ZC1% ZC1 ON ZC1_LOCCTR=RD_XIDLOC  
					AND ZC1.D_E_L_E_T_=''

				INNER JOIN %table:ZC7% ZC7 ON ZC7_IDFOL=RD_XIDFOL 
					AND ZC7.D_E_L_E_T_=''

				INNER JOIN %table:RC0% RC0 ON RC0_CODTIT=%Exp:RC1->RC1_CODTIT%
					AND RC0.D_E_L_E_T_=''

				INNER JOIN 
					(SELECT SRD1.RD_MAT MATRICULA, SRD1.RD_VALOR, SRD1.RD_XIDFOL 
					FROM  %table:SRD% SRD1
					INNER JOIN  %table:SRA% SRA ON RA_MAT=SRD1.RD_MAT %EXP:cCndAnd%  AND SRA.D_E_L_E_T_='' 
					WHERE  (SRD1.RD_PD = %Exp:AVKEY(cTipVer,"RD_PD")% OR SRD1.RD_PD = %Exp:AVKEY(c2TipVer,"RD_PD")% ) 
					AND SRD1.RD_XNUMTIT = %Exp:RC1->RC1_NUMTIT% AND SRD1.D_E_L_E_T_='') AS TBQTDEBOLSA ON TBQTDEBOLSA.MATRICULA = SRD.RD_MAT AND TBQTDEBOLSA.RD_XIDFOL = SRD.RD_XIDFOL

				INNER JOIN
					(SELECT SRD2.RD_MAT, SRD2.RD_XIDFOL, SRD2.RD_VALOR FROM  %table:SRD% SRD2 INNER JOIN  %table:SRA% SRA ON RA_MAT=RD_MAT %EXP:cCndAnd%
					AND SRA.D_E_L_E_T_='' 
					WHERE SRD2.RD_PD='004' AND SRD2.D_E_L_E_T_='' ) AS TBTOTALBOLSA ON TBTOTALBOLSA.RD_MAT = SRD.RD_MAT AND TBTOTALBOLSA.RD_XIDFOL = SRD.RD_XIDFOL

				LEFT JOIN
					(SELECT SRD3.RD_MAT, SRD3.RD_XIDFOL, SRD3.RD_VALOR FROM  %table:SRD% SRD3 INNER JOIN  %table:SRA% SRA ON RA_MAT=RD_MAT %EXP:cCndAnd% AND SRA.D_E_L_E_T_='' 
					WHERE RD_PD='277' AND SRD3.D_E_L_E_T_='' ) AS TBTOTALAUXTRANSP ON TBTOTALAUXTRANSP.RD_MAT = SRD.RD_MAT AND TBTOTALAUXTRANSP.RD_XIDFOL = SRD.RD_XIDFOL

				LEFT JOIN
					(SELECT SRD4.RD_MAT, SRD4.RD_XIDFOL, SRD4.RD_VALOR FROM  %table:SRD% SRD4 INNER JOIN  %table:SRA% SRA ON RA_MAT=RD_MAT %EXP:cCndAnd% AND SRA.D_E_L_E_T_='' 
					WHERE RD_PD='509' AND SRD4.D_E_L_E_T_='' ) AS TBVALORIRRF ON TBVALORIRRF.RD_MAT = SRD.RD_MAT AND TBVALORIRRF.RD_XIDFOL = SRD.RD_XIDFOL

				LEFT JOIN
					(SELECT SRD5.RD_MAT, SRD5.RD_XIDFOL, SRD5.RD_VALOR FROM  %table:SRD% SRD5 
					WHERE RD_PD IN ('530','554') AND SRD5.D_E_L_E_T_='' ) AS TBVALORPENSAO ON TBVALORPENSAO.RD_MAT = SRD.RD_MAT AND TBVALORPENSAO.RD_XIDFOL = SRD.RD_XIDFOL

			WHERE SRD.D_E_L_E_T_=''
				AND RD_XNUMTIT=%Exp:RC1->RC1_NUMTIT%

			GROUP BY ZC7_COMPET, SRD.RD_XIDCNT, SRD.RD_XIDLOC, SRD.RD_XIDFOL, ZC1.ZC1_RAZSOC
		EndSql

	Endif

	//GETLastQuery()[2]
	(cTab)->(dbSelectArea((cTab)))
	Count To nTotMov

	(cTab)->(dbGoTop())
	If (cTab)->(!EOF())
		nTotPag := nTotMov / 73

		If INT(nTotPag) < nTotPag
			nTotPag := INT(nTotPag) + 1
		Endif

		FERASE("\spool\"+cNomeRel+".pdf")
		FERASE("\spool\"+cNomeRel+".rel")

		oPrint:= FWMSPrinter():New(cNomeRel+".rel",IMP_PDF,.F.,"\spool\",.t.,.F.,,,.T.,.T.,,.T.)
		oPrint:SetLandscape()
		oPrint:SetResolution(78)
		oPrint:SetPaperSize(DMPAPER_A4)
		oPrint:SetMargin(40,40,40,40)
		oPrint:nDevice  := IMP_PDF
		oPrint:cPathPDF := "\spool\"
		oPrint:lServer  := .T.
		oPrint:lViewPDF := .F.
		oPrint:StartPage()

		CJBK03LR(cNumTit,cDescr,dDtaPag,lXpensao)

		While (cTab)->(!EOF())

			If (nLin > 590)
				oPrint:EndPage()
				oPrint:StartPage()
				nAtuPag++
				CJBK03LR(cNumTit,cDescr,dDtaPag,lXpensao)
			Endif
			If lImpIrf
				//dVenc := STOD(dVenc)
				dVenc := DTOC(RC1->RC1_VENCTO)

				oPrint:Say(nLin,12,(cTab)->RD_MAT,oFnt9) //Matricula
				oPrint:Say(nLin,62,ALLTRIM(GetAdvFVal("SRA","RA_NOME" ,XFILIAL("SRA") + (cTab)->RD_MAT,1)),oFnt9) //Nome
				oPrint:Say(nLin,222,dVenc,oFnt9) //Vencimento
				oPrint:Say(nLin,277,(cTab)->RD_XIDFOL,oFnt9)//ID Folha
				oPrint:Say(nLin,337,(cTab)->RD_PERIODO,oFnt9)//ID Folha
				oPrint:Say(nLin,397,(cTab)->RD_XIDCNT,oFnt9)//Contrato
				oPrint:Say(nLin,457,(cTab)->RD_XIDLOC,oFnt9)//Local
				
				//Calculo do liquido a receber, pois o registro J99 não deve gravar o campo RD_XNUMTIT no ponto de entrada GP650CPO
				
				cBaseIr  := Val(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"A05"))
				cValorIr := Val(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"509"))
				cLiqRec  := TRANSFORM(cBaseIr - cValorIr, "@E 999,999.99")
				
				oPrint:Say(nLin,520,TRIM(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"J99")),oFnt9)//Liq. Receber
				oPrint:Say(nLin,577,TRIM(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"004")),oFnt9)//Bolsa Aux.
				oPrint:Say(nLin,637,TRIM(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"277")),oFnt9)//Aux. Trans
				oPrint:Say(nLin,697,TRIM(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"A05")),oFnt9)//Base IR
				oPrint:Say(nLin,757,TRIM(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"509")),oFnt9)//Valor IR
				oPrint:Say(nLin,817,TRIM(CJBK03Valor((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"554")),oFnt9)//Pensao Alim.

				nTotGer += CJBK03Tot((cTab)->RD_XIDFOL,(cTab)->RD_MAT,(cTab)->RD_PERIODO,"509")
				nLin += 10

				(cTab)->(dbSkip())

				If (cTab)->(EOF())
					nLin := 590
					oPrint:Box(590,736,600,870)
					oPrint:Line(nLin,798,600,798)
					oPrint:Say(nLin+8,739,"TOTAL (R$)",oFnt9)
					oPrint:SayAlign(nLin-1,801,TRIM(TRANSFORM(nTotGer,cPictVrl)),oFnt9,68,,,1,0)
					oPrint:SayAlign(nLin-1,11,"Gerado automaticamente pelo Sistema - Protheus",oFnt9,348,,,0,0)
				EndIf

			Else
				//	nOutros := (cTab)->(TOTALBOLSA - TOTALAUXTRANSP - VALORIRRF - VALORPENSAO - LIQUIDOAPAGAR)
				//	Nessa Coluna, as verbas ainda não foram definidas, o valor ficará ZERO

				oPrint:Say(nLin,11,(cTab)->COMPETENCIA,oFnt9)
				oPrint:Say(nLin,61,(cTab)->CONVENIO,oFnt9)
				oPrint:Say(nLin,201,(cTab)->DESCCONV,oFnt9)
				oPrint:SayAlign(nLin-10,441,CVALTOCHAR((cTab)->QTDEBOLSA),oFnt9,46,,,1,0)
				oPrint:SayAlign(nLin-10,491,TRIM(TRANSFORM((cTab)->TOTALBOLSA,cPictVrl)),oFnt9,58,,,1,0)
				oPrint:SayAlign(nLin-10,553,TRIM(TRANSFORM((cTab)->TOTALAUXTRANSP,cPictVrl)),oFnt9,58,,,1,0)
				oPrint:SayAlign(nLin-10,615,TRIM(TRANSFORM((cTab)->VALORIRRF,cPictVrl)),oFnt9,58,,,1,0)
				oPrint:SayAlign(nLin-10,677,TRIM(TRANSFORM((cTab)->VALORPENSAO,cPictVrl)),oFnt9,58,,,1,0)
				oPrint:SayAlign(nLin-10,739,TRIM(TRANSFORM(nOutros,cPictVrl)),oFnt9,58,,,1,0)
				oPrint:SayAlign(nLin-10,801,TRIM(TRANSFORM((cTab)->LIQUIDOAPAGAR,cPictVrl)),oFnt9,68,,,1,0)

				nTotGer += (cTab)->LIQUIDOAPAGAR
				nLin += 10

				(cTab)->(dbSkip())

				If (cTab)->(Eof())
					nLin := 590
					oPrint:Box(590,736,600,870)
					oPrint:Line(nLin,798,600,798)
					oPrint:Say(nLin+8,739,"TOTAL (R$)",oFnt9)
					oPrint:SayAlign(nLin-1,801,TRIM(TRANSFORM(nTotGer,cPictVrl)),oFnt9,68,,,1,0)
					oPrint:SayAlign(nLin-1,11,"Gerado automaticamente pelo Sistema - Protheus",oFnt9,348,,,0,0)
				EndIf
			EndIf
		Enddo

		oPrint:EndPage()
		oPrint:Print()
		FreeObj(oPrint)
	Endif
	(cTab)->(dbCloseArea())

	cNomeRel := cNomeRel + ".pdf"
	cDirRel := "\spool\" + cNomeRel
	lRet := FILE(cDirRel) //Verifica se gerou o PDF

Return lRet


/*/{Protheus.doc} CJBK03LR
Rotina de impressão do layout do relatório
@author carlos.henrique
@since 30/01/2019
@version undefined
@type function
@history  30/07/2020, Ajuste de layout
/*/
Static function CJBK03LR(cNumTit,cDescr,dDtaPag,lXpensao)

Default lXpensao:= .f.

	If lImpIrf
		oPrint:Box(10,10,590,870)

		oPrint:SayBitmap(01,20,cLogo,080,090)
		oPrint:Line(10,10,10,870)
		oPrint:Line(10,120,85,120)
		oPrint:Line(30,120,30,870)
		oPrint:Line(30,220,85,220)

		If !lXpensao
			oPrint:SAY(24,380,"RELATÓRIO APURAÇÃO IR DE BOLSA AUXÍLIO",oFntb14)
		Else
			oPrint:SAY(24,380,"RELATÓRIO APURAÇÃO IR DE PENSÃO",oFntb14)
		Endif

		oPrint:SAY(40,122,"Número:",oFntb9)
		oPrint:Say(40,222,cNumTit,oFnt9)
		oPrint:Line(42,120,42,870)
		oPrint:SAY(50,122,"Descritivo:",oFntb9)
		oPrint:Say(50,222,cDescr,oFnt9)
		oPrint:Line(52,120,52,870)
		oPrint:SAY(60,122,"Data de Pagamento:",oFntb9)
		oPrint:Say(60,222,DTOC(dDtaPag),oFnt9)
		oPrint:Line(62,120,62,870)
		oPrint:SAY(70,122,"Data da Integração:",oFntb9)
		oPrint:Say(70,222,DTOC(DATE()),oFnt9)
		oPrint:Line(72,120,72,870) 
		oPrint:SAY(80,122,"Página:",oFntb9)
		oPrint:Say(80,222,CVALTOCHAR(nAtuPag) +  " de " + CVALTOCHAR(nTotPag) ,oFnt9)

		nLin := 85
		oPrint:Line(nLin,10,nLin,870)
		oPrint:Line(nLin,61,590,61)
		oPrint:Line(nLin,220,590,220)
		oPrint:Line(nLin,275,590,275)
		oPrint:Line(nLin,335,590,335)
		oPrint:Line(nLin,395,590,395)
		oPrint:Line(nLin,455,590,455)
		oPrint:Line(nLin,515,590,515)
		oPrint:Line(nLin,575,590,575)
		oPrint:Line(nLin,635,590,635)
		oPrint:Line(nLin,695,590,695)
		oPrint:Line(nLin,755,590,755)
		oPrint:Line(nLin,815,590,815)
		oPrint:SAY(nLin+9,11,"Matricula",oFntb9)
		oPrint:SAY(nLin+9,61,"Nome",oFntb9)
		oPrint:SAY(nLin+9,220,"Vencimento")
		oPrint:SAY(nLin+9,275,"ID Folha",oFntb9)
		oPrint:SAY(nLin+9,335,"Competencia",oFntb9)
		oPrint:SAY(nLin+9,395,"Contrato",oFntb9)
		oPrint:SAY(nLin+9,455,"Local",oFntb9)
		oPrint:SAY(nLin+9,515,"Liq. Receber",oFntb9)
		oPrint:SAY(nLin+9,575,"Bolsa Aux.",oFntb9)
		oPrint:SAY(nLin+9,635,"Aux. Trans.",oFntb9)
		oPrint:SAY(nLin+9,695,"Base IR",oFntb9)
		oPrint:SAY(nLin+9,755,"Valor IR",oFntb9)
		oPrint:SAY(nLin+9,815,"Pensao Alim.",oFntb9)
		oPrint:Line(nLin+12,10,nLin+12,870)

		nLin += 22

	Else
		oPrint:Box(10,10,590,870)

		oPrint:SayBitmap(01,20,cLogo,080,090)
		oPrint:Line(10,10,10,870)
		oPrint:Line(10,120,85,120)
		oPrint:Line(30,120,30,870)
		oPrint:Line(30,220,85,220)

		If !lXpensao
			oPrint:SAY(24,380,"RELATÓRIO SINTÉTICO PAGAMENTO DE BOLSA-AUXÍLIO",oFntb14)    
		Else
			oPrint:SAY(24,380,"RELATÓRIO SINTÉTICO PAGAMENTO DE PENSÃO",oFntb14)
		Endif

		oPrint:SAY(40,122,"Número:",oFntb9)
		oPrint:Say(40,222,cNumTit,oFnt9)
		oPrint:Line(42,120,42,870)
		oPrint:SAY(50,122,"Descritivo:",oFntb9)
		oPrint:Say(50,222,cDescr,oFnt9)
		oPrint:Line(52,120,52,870)
		oPrint:SAY(60,122,"Data de Pagamento:",oFntb9)
		oPrint:Say(60,222,DTOC(dDtaPag),oFnt9)
		oPrint:Line(62,120,62,870)
		oPrint:SAY(70,122,"Data da Integração:",oFntb9)
		oPrint:Say(70,222,DTOC(DATE()),oFnt9)
		oPrint:Line(72,120,72,870)
		oPrint:SAY(80,122,"Página:",oFntb9)
		oPrint:Say(80,222,CVALTOCHAR(nAtuPag) +  " de " + CVALTOCHAR(nTotPag) ,oFnt9)

		nLin := 85
		oPrint:Line(nLin,10,nLin,870)
		oPrint:Line(nLin,60,590,60)
		oPrint:Line(nLin,200,590,200)
		oPrint:Line(nLin,440,590,440)
		oPrint:Line(nLin,488,590,488)
		oPrint:Line(nLin,550,590,550)
		oPrint:Line(nLin,612,590,612)
		oPrint:Line(nLin,674,590,674)
		oPrint:Line(nLin,736,590,736)
		oPrint:Line(nLin,798,590,798)
		oPrint:SAY(nLin+9,11,"Competência",oFntb9)
		oPrint:SAY(nLin+9,61,"Contrato\Local\Folha",oFntb9)
		oPrint:SAY(nLin+9,201,"Descrição", oFntb9)
		oPrint:SAY(nLin+9,441,"Qtde. Bolsas",oFntb9)
		oPrint:SAY(nLin+9,491,"Total Bolsa", oFntb9)	//	"Total de Bolsas", oFntb9)
		oPrint:SAY(nLin+9,553,"Total Transp.", oFntb9)	//	"Tot.Aux.Transp.", oFntb9)
		oPrint:SAY(nLin+9,615,"Valor IR", oFntb9)	//	"IR e Pensão", oFntb9)
		oPrint:SAY(nLin+9,677,"Valor Pensão", oFntb9)	//	"CI Devida", oFntb9)
		oPrint:SAY(nLin+9,739,"Outros", oFntb9)	//	"CI Recebida", oFntb9)
		oPrint:SAY(nLin+9,801,"Líquido a Pagar", oFntb9)	//	"Total da Folha", oFntb9)
		oPrint:Line(nLin+12,10,nLin+12,870)

		nLin += 22
	EndIf

Return

/*/{Protheus.doc} CJBK03LOG
Rotina de gravação do log
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CJBK03LOG(nTpLog,cMsgLog,cStatus,cLogCom,cIdSol)
	local nX		:= 0
	default cStatus	:= ""
	default cLogCom	:= ""
	default cIdSol	:= ""
	default cMsgLog	:= ""

	Do Case
	Case nTpLog == 1 //Exibe log em tela ou console

		if IsBlind()
			CONOUT(cMsgLog)
		else
			MSGALERT(cMsgLog)
		endif

	CASE nTpLog == 2 //Grava log na tabela RC1 posicionada

		RECLOCK("RC1",.F.)
		RC1->RC1_XMSLOG:= cMsgLog
		RC1->RC1_INTEGR:= cStatus
		RC1->RC1_XLGCOM:= cLogCom
		RC1->RC1_XIDFLG:= cIdSol
		RC1->RC1_XDTINT:= DATE()
		MSUNLOCK()

	CASE nTpLog == 3 //Popula array para grava fora da transação

		AADD(_aGeraLog,{RC1->(RECNO()),cMsgLog,cStatus,cLogCom,0})

	CASE nTpLog == 4 //Grava dados do array _aGeraLog

		for nX:=1 to len(_aGeraLog)
			RC1->(DbGoto(_aGeraLog[nX][1]))
			RECLOCK("RC1",.F.)
			RC1->RC1_XMSLOG:= _aGeraLog[nX][2]
			RC1->RC1_INTEGR:= _aGeraLog[nX][3]
			RC1->RC1_XLGCOM:= _aGeraLog[nX][4]
			RC1->RC1_XIDFLG:= _aGeraLog[nX][5]
			RC1->RC1_XDTINT:= DATE()
			MSUNLOCK()
		next

		_aGeraLog:= {}

	Otherwise
		CONOUT(cMsgLog)
	EndCase CASE

return
/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
Static Function Scheddef()
	Local aParam := {"P","CJOBK03","RC1",{},""}
Return aParam

/*/{Protheus.doc} CJBK03TIT
Gera titulo RC1
@author totvs
@since 06/06/2019
@version undefined

@type function
/*/
STATIC Function CJBK03TIT(_lJob)
	Local nI 		  	:= 0
	Private aRetFiltro	:= {}
	Private cRC0Filter	:= ""
	Private cTipoCont 	:= 3                              // Tipo de Contabilizacao: 1-Folha Pagamento;2-Provisao;3-Ambas
	Private lDrop	 	:= .F.
	Private cAnoMes	 	:= ""
	Private nTpImpre 	:= 2
	Private aLogFile	:= {}
	Private aLogTitle	:= {}
	Private cGeraBen	:= ""
	Private aInssEmp	:= If( Type("aInssEmp") == "A", aInssEmp, {} ) // Array com os dados do parametro 14
	Private lRc1Arelin 	:= RC1->( FieldPos('RC1_ARELIN') ) > 0
	Private lTamTitDif  := ChkFile("RJ1") .And. TamSX3( "RC1_NUMTIT" )[1] <> TamSX3( "RJ1_NUMTIT" )[1]
	Private lMsgRJ1     := .T.
	Private cFilLastNum	:= ""
	Private lTitLog1 	:= .F.
	Private lTitLog2 	:= .F.
	Private lTitLog3 	:= .F.

	lTitLog1 := .F.
	lTitLog2 := .F.

	If !(fValidFun({"RC1","RC0","CTT","SRZ","SRT","SRG","SRH"}))
		Return( nil )
	Endif

	If !(_lJob)
		ProcGpe({|lEnd| GPM650Proc(_lJob) })  // Chamada do Processamento
	else
		GPM650Proc(_lJob)
	endif

	If !Empty(aLogFile)
		AAdd(aLogTitle ,{OemToAnsi("STR0022")})
		ASort(aLogFile,,,{|x,y| x[1] < y[1]}) // Ordena o Log de duplicidade de t?ulos e do cadastro de fornecedores

		For nI := 1 To Len(aLogFile)
			ADel(aLogFile[nI],1)
		Next nI

		fMakeLog( aLogFile, aLogTitle, "GPEM650", NIL, FunName())
		aLogFile := {}
	EndIf

Return Nil

/*/{Protheus.doc} GPM650Proc
Programa de geracao de Titulos	
@author totvs
@since 06/06/2019
@version undefined

@type function
/*/
Static Function GPM650Proc(_lJob)
	Local cTitProc  := ""
	//Local nCnt      := 0
	Local nCnt1     := 0
	//Local nFol13Sal := 0
	Local nNroSem   := 0
	Local lCabec    := .F.
	Local lVenc    := .F.
	Local cCpoPadRC1 := ""
	Local cCposRC0  := ""
	Local cRC1Cpo   := ""
	Local cRC1Conf  := ""
	Local nRecnoRC1 := 0

	//Local aArea			:= GetArea()
	//Local aAreaSM0		:= SM0->( GetArea() )
	//Local cCodEmp		:= SM0->M0_CODIGO
	Local cModoRC0		:= ""
	//Local aFilProc		:= {}
	//Local nCont			:= 0
	//Local nFatDes 		:= 0
	//Local nFatFol 		:= 0
	//Local nFatTot 		:= 0
	//Local nFilial		:= 0
	//Local nProp			:= 0
	//Local cRecFatEmp	:= ""
	//Local aTabS033		:= {}
	//Local lRecDesTot	:= .F.
	//Local lRec2DesTot	:= .F.
	Local lChkRHH 		:= Sx2ChkTable( "RHH" )
	Local cWhereRC0 	:= ""
	Local cAliasRC0 	:= ""
	Local cCamposRC0 	:= ""

//????????????????????????????????
//?Define Variaveis PRIVATE DO PROGRAMA                         ?
//????????????????????????????????
	Private aCposUsu    := {}
	Private dDataVenc   := CTOD("")
	Private cAliasCC    := "CTT"
	Private lSrz		   :=	.F.
	Private aPerAberto  := {}
	Private aPerFechado := {}
	Private cProcesso   := ""
	Private cRoteiro    := ""
	Private lConsiste   := SuperGetMv("MV_CONDUPL",,.F.) //.T. - Consiste / .F. - N? consiste
	Private cChaveDup   := SuperGetMv("MV_CHAVDUP",,"1") //"1" - Chave sem data de vencimento / "2" - Chave com data de vencimento
	Private aRatTit     := {}
	Private aRecTabs	:= {}
	DEFAULT lEnd        := .F.

	_SetOwnerPrvt(	"aAliasFields"	, {} )

//?????????????????????????????????
//?Variaveis utilizadas para parametros                          ?
//?mv_par01        //  Filial De                                 ?
//?mv_par02        //  Filial Ate                                ?
//?mv_par03        //  Centro de Custo De                        ?
//?mv_par04        //  Centro de Custo Ate                       ?
//?mv_par05        //  Matricula De                              ?
//?mv_par06        //  Matricula Ate                             ?
//?mv_par07        //  Dt. Busca Pagto De                        ?
//?mv_par08        //  Dt. Busca Pagto Ate                       ?
//?mv_par09        //  Codigo Titulo De                          ?
//?mv_par10        //  Codigo Titulo Ate                         ?
//?mv_par11        //  Data de Emissao                           ?
//?mv_par12        //  Competencia                               ?
//?mv_par13        //  Data de vencimento                        ?
//?????????????????????????????????
	cFilDeT     := mv_par01
	cFilAteT    := mv_par02
	cCCDeT      := mv_par03
	cCCAteT     := mv_par04
	cMatDeT     := mv_par05
	cMatAteT    := mv_par06
	dDataDeT    := mv_par07
	dDataAteT   := mv_par08
	cCodTitDe   := mv_par09
	cCodTitAte  := mv_par10
	dDtEmisTit  := mv_par11
	cCompetTit  := mv_par12
	dVctoInf	 := mv_par13
	cAnoMes    :=substr(cCompetTit,3,4)+substr(cCompetTit,1,2)

//????????????????????????????????
//?Campos do RC1 (padrao do sistema)				                  ?
//????????????????????????????????
	If cpaisloc == "BRA"

		cCpoPadRC1 := "RC1_FILIAL/RC1_INTEGR/RC1_FILTIT/RC1_CODTIT/RC1_DESCRI/RC1_PREFIX/"+;
			"RC1_NUMTIT/RC1_TIPO/RC1_NATURE/RC1_FORNEC/RC1_EMISSA/RC1_VENCTO/"  +;
			"RC1_VENREA/RC1_VALOR/RC1_DTBUSI/RC1_DTBUSF/RC1_CODRET/RC1_LOJA"
	Else

		cCpoPadRC1 := "RC1_FILIAL/RC1_INTEGR/RC1_FILTIT/RC1_CODTIT/RC1_DESCRI/RC1_PREFIX/"+;
			"RC1_NUMTIT/RC1_TIPO/RC1_NATURE/RC1_FORNEC/RC1_EMISSA/RC1_VENCTO/"  +;
			"RC1_VENREA/RC1_VALOR/RC1_DTBUSI/RC1_DTBUSF"
	EndIf

//????????????????????????????????
//?Carrega os Filtros                                 	 	      ?
//????????????????????????????????
	cRC0Filter	:= GpFltAlsGet( aRetFiltro , "RC0" )

//????????????????????????????????
//?Variaveis utilizadas para geracao do SRZ via procedure     	?
//????????????????????????????????
	lFolPgto    := .F.
	lFol13Sl    := .F.

//????????????????????????????????
//?Grava no array os campos do usuario criados no arquivo RC0 e ?
//?RC1, assegurando que os dois tem o mesmo tipo e tamanho.     ?
//????????????????????????????????
	dbSelectArea("SX3")
	dbSetOrder(1)
	dbSeek("RC1")
	While !Eof() .And. X3_ARQUIVO == "RC1"
		If !(AllTrim(X3_CAMPO) $ cCpoPadRC1)
			cRC1Cpo   := X3_CAMPO
			cRC1Conf  := X3_TIPO+StrZero(X3_TAMANHO, 3)+StrZero(X3_DECIMAL, 1)
			nRecnoRC1 := RECNO()
			dbSetOrder(2)
			If dbSeek("RC0" + Right(cRC1Cpo, 7))
				If X3_TIPO+StrZero(X3_TAMANHO, 3)+StrZero(X3_DECIMAL, 1) == cRC1Conf
					Aadd(aCposUsu, { "(cAliasRC0)->"+X3_CAMPO, "RC1->" + cRC1Cpo, Nil })
				EndIf
			EndIf
			dbSetOrder(1)
			dbGoTo(nRecnoRC1)
		EndIf
		dbSkip()
	EndDo

//????????????????????????????????
//?Verifica se existem os campos RC1_CC e RC1_MAT		         ?
//????????????????????????????????
	dbSelectArea( "RC1" )

//????????????????????????????????
//?Verifica existencia dos cpos RC0_ALIADV/RC0_CPOBDV/RC0_FILTDV?
//????????????????????????????????
	cFilAte := xFilial( "RC0", cFilAteT )

	xRetModo( "RC0" , NIL , .F. , @cModoRC0 , NIL )

	cAliasRC0	:= GetNextAlias()
	cCamposRC0	:= "%RC0_FILIAL, RC0_CODTIT, RC0_TIPTIT, RC0_VERBAS, RC0_DESCRI, RC0_AGRUPA,  "
	cCamposRC0	+= "RC0_DMVENC, RC0_MESPGT, RC0_DSVENC, RC0_FORNEC, RC0_LOJA, RC0_NATURE, RC0_ANTPGT, "
	cCamposRC0	+= "RC0_PREFIX, RC0_TIPO, RC0_FILTRV, RC0_FILTRF, RC0_FILTRD, RC0_ALIAS, RC0_SEQUEN,  "

	If cpaisloc == "BRA"
		cCamposRC0 += "RC0_CODRET, RC0_TPRET, "
		If RC0->(ColumnPos( "RC0_GERBEN")) > 0
			cCamposRC0 += " RC0_GERBEN,"
		EndIf
		cCamposRC0 += " RC0_DIAUTI, RC0_ALIADV, RC0_CPODTV, RC0_FILTDV, RC0_CPODTR"
	Else
		cCamposRC0 += " RC0_DIAUTI, RC0_ALIADV, RC0_CPODTV, RC0_FILTDV, RC0_CPODTR"
	EndIf

	For nCnt1 := 1 To Len(aCposUsu)
		cCamposRC0 += ", " + SubStr(aCposUsu[nCnt1,1], 14)
	Next nCnt1

	cCamposRC0 += "%"

	cWhereRC0 := "%RC0.RC0_FILIAL >= " + "'" + xFilial("RC0",cFilDeT)  + "'" + " AND "
	cWhereRC0 += "RC0.RC0_FILIAL <= " + "'" + xFilial("RC0",cFilATet) + "'" + " AND "
	cWhereRC0 += "RC0.RC0_CODTIT >= " + "'" + cCodTitDe  + "'" + " AND "
	cWhereRC0 += "RC0.RC0_CODTIT <= " + "'" + cCodTitAte + "'" + "%"

	BeginSql alias cAliasRC0
		SELECT %exp:cCamposRC0%
		FROM  %table:RC0% RC0
		WHERE %exp:cWhereRC0% AND RC0.%notDel%
	EndSql

	if !(_lJob)
		GPProcRegua((cAliasRC0)->(RecCount()))
	ENDIF

	While (cAliasRC0)->(!EoF())

		cNovoTit 	:= ""

		if !(_lJob)
			GPIncProc("Processando...") // "Processando..."
		ENDIF

		If (cAliasRC0)->RC0_CODTIT < cCodTitDe .Or. (cAliasRC0)->RC0_CODTIT > cCodTitAte
			dbSelectArea((cAliasRC0))
			(cAliasRC0)->(dbSkip())
			Loop
		EndIf

		If !Empty( cRC0Filter )
			If !( &( cRC0Filter ) )
				(cAliasRC0)->( dbSkip())
				Loop
			EndIf
		EndIf

		//??????????????????????????????????????
		//?Verifica existencia da nova tabela de Dissidio Acumulado (RHH) SE a		 ?
		//?geracao de Titulo for de Dissidio. Se NAO existir a tabela sera			 ?
		//?apresentada a mensagem informando a necessidade da execucao do update 	 ?
		//?150 para a criacao e impede a execucao da geracao somente para o tipo de?
		//?titulo 006 - INSS - DISSIDIO ate que o update seja executado.		   	    ?
		//??????????????????????????????????????
		If (cAliasRC0)->RC0_TIPTIT == '1' .and. '006' $ AllTrim( (cAliasRC0)->RC0_VERBAS ) .and. !lChkRHH

			Aviso( "STR0008", "STR0015" + CRLF + "STR0016", { "STR0017" } )	//"Atencao" ## "Execute a op?o do compatibilizador referente ?cria?o da nova tabela de Diss?io Acumulado. Para maiores informa?es verifique respectivo Boletim T?nico."
			//"Somente os t?ulos de tipo 006 - INSS - Dissidio N? ser? gerados at?que o compatibilizador seja executado." ## "OK"

			(cAliasRC0)->( dbSkip())
			Loop
		EndIf

		cFilAtu		:= (cAliasRC0)->RC0_FILIAL
		cCodTit		:= (cAliasRC0)->RC0_CODTIT
		cDescri		:= (cAliasRC0)->RC0_DESCRI
		cAgrupa		:= (cAliasRC0)->RC0_AGRUPA
		cDmVenc		:= (cAliasRC0)->RC0_DMVENC
		cMesPgt		:= (cAliasRC0)->RC0_MESPGT
		cDsVenc		:= (cAliasRC0)->RC0_DSVENC
		cFornec		:= (cAliasRC0)->RC0_FORNEC
		cLoja		:= (cAliasRC0)->RC0_LOJA
		cNature		:= (cAliasRC0)->RC0_NATURE
		cPrefix		:= (cAliasRC0)->RC0_PREFIX
		cTipTit		:= (cAliasRC0)->RC0_TIPTIT
		cIdentTit	:= AllTrim((cAliasRC0)->RC0_TIPO)
		cFiltrLan	:= AllTrim((cAliasRC0)->RC0_FILTRV)
		cFiltrSRA	:= (cAliasRC0)->RC0_FILTRF
		cCpoDtLan	:= Alltrim((cAliasRC0)->RC0_FILTRD)
		cAliasLan	:= If (!Empty( (cAliasRC0)->RC0_ALIAS ),(cAliasRC0)->RC0_ALIAS, "RC0")

		If cpaisloc == "BRA"
			cCodRetTit := (cAliasRC0)->RC0_CODRET
			cTipoRet  := (cAliasRC0)->RC0_TPRET
			If RC0->(ColumnPos( "RC0_GERBEN")) > 0
				cGeraBen  := (cAliasRC0)->RC0_GERBEN
			EndIf
		Else
			cCodRetTit := ""
			cTipoRet  := ""
			cGeraBen  := ""
		EndIf

		cSRACodRet := ""

		lSrz	   := If( cAliasLan == "SRZ" , .T. , .F. )
		cDiaUtil  := (cAliasRC0)->RC0_DIAUTI
		cVerbas   := ""
		lCabec    := .F.
		lVenc    := .F.

		cAliasCab := (cAliasRC0)->RC0_ALIADV
		cCpoDtCab := AllTrim((cAliasRC0)->RC0_CPODTV)
		cFiltrCab := (cAliasRC0)->RC0_FILTDV
		cCpoDtRel := (cAliasRC0)->RC0_CPODTR
		lCabec    := (!Empty((cAliasRC0)->RC0_ALIADV) .And. !Empty((cAliasRC0)->RC0_CPODTV)) .And. ((cAliasRC0)->RC0_ALIAS <> (cAliasRC0)->RC0_ALIADV) .And. Empty(dVctoInf)
		lVenc     := !lCabec .And. (!Empty((cAliasRC0)->RC0_ALIADV) .And. !Empty((cAliasRC0)->RC0_CPODTV) .And. (cAliasRC0)->RC0_ALIAS == (cAliasRC0)->RC0_ALIADV )

		//????????????????????????????????
		//?Grava o conteudo dos campos de usuario do RC0 em aCposUsu	   ?
		//????????????????????????????????
		For nCnt1 := 1 To Len(aCposUsu)
			cCposRC0          := aCposUsu[nCnt1,1]
			aCposUsu[nCnt1,3] := &cCposRC0
		Next nCnt1

		//????????????????????????????????
		//?Calcula data de vencimento do titulo			                  ?
		//????????????????????????????????
		dDataVenc := CTOD("")
		If !Empty(cDmVenc) .And. !Empty(cMesPgt)  // Dia do mes para o vencimento
			If cMesPgt == "3" // Mes Seguinte ao Pagamento
				cNovMes :=  Strzero(Month(dDataDeT),2)
				cNovAno := Str(Year(dDataDeT),4)
				//-- Calcula o mes seguinte a data de apuracao.
				cNovMes := If(cNovMes == "12", "01", StrZero(Val(cNovMes)+1,2))
				cNovAno := If(cNovMes == "01", StrZero(Val(cNovAno)+1,4), cNovAno)
			Else
				cNovMes :=  Left(cCompetTit,2)
				cNovAno := Right(cCompetTit,4)
				If cMesPgt == "2" // Mes Seguinte
					cNovMes := If(cNovMes == "12", "01", StrZero(Val(cNovMes)+1,2))
					cNovAno := If(cNovMes == "01", StrZero(Val(cNovAno)+1,4), cNovAno)
				EndIf
			EndIf

			dDataVenc := CTOD(cDmVenc + "/" + cNovMes + "/" + cNovAno)
			//-- Se gerou um data invalida pois o dia nao existe para o mes gerado
			IF Empty(dDataVenc)
				//-- Assume o maior dia do mes gerado
				dDataVenc:= CTOD(Strzero(F_ULTDIA(Ctod("01/"+cNovMes+"/"+cNovAno)),2) + "/" + cNovMes + "/" + cNovAno)
			Endif

		ElseIf !Empty(cDsVenc)   // Dia da Semana para o vencimento
			nNroSem := If(DOW(dDataAteT) > Len(cDsVenc), 7, 0)
			dDataVenc := (dDataAteT - DOW(dDataAteT) + Val(cDsVenc) + nNroSem)
		EndIf

		//????????????????????????????????
		//?Verifica se existem outros registro e os carregas em cVerbas ?
		//????????????????????????????????
		While !Eof() .And. (cAliasRC0)->RC0_FILIAL+(cAliasRC0)->RC0_CODTIT == cFilAtu+cCodTit
			cVerbas += AllTrim((cAliasRC0)->RC0_VERBAS)
			(cAliasRC0)->( dbSkip())
		EndDo

		If cTipTit == "1"

			cTitProc := Left(cVerbas,3)

			//Tratamento de pensão //TODO - Avaliar como será
			If cTitProc == "004"
				If Empty(cAliasLan)
					cAliasLan := "RC0"
				EndIf

				aRatTit := {}
				fGerPens(@lEnd)
			endif

		ElseIf cTipTit == "2"

			If Empty(cAliasLan)
				dbSelectArea( (cAliasRC0) )
				Loop
			EndIf

			aRatTit := {}
			fTitUsu(@lEnd,lCabec,lVenc)

		EndIf

		cFilAte := xFilial( "RC0", cFilAteT )
		dbSelectArea( (cAliasRC0) )
	EndDo

Return Nil

/*/{Protheus.doc} fGerPens
Monta valores de pensao e grava no arquivo de titulos
@author totvs
@since 06/06/2019
@version undefined

@type function
/*/
Static Function fGerPens(lEnd)
	Local cAlias		:= ALIAS()
	Local aArea
	Local aCodFol		:= {}
	Local aValBenef		:= {}
	//Local aOrdBagRC		:= {}
	Local aRotAux		:= {}
	Local nValor		:= 0
	Local nValTotal		:= 0
	//Local cAliasRC		:= ""
	Local cFilRotAux	:= "#########"
	//Local cRCName
	Local cFilialAnt
	Local cCCAnt
	Local nCntB			:= 0
	Local cAgrupAnt
	Local dDataRef
	//Local cQuery		:= ""
	Local cAliasSRA		:= "SRA"
	//Local cAliasCount	:= ""
	//Local cQry			:= ""
	//Local cCount		:= ""
	//Local lQuery		:= .F.
	//Local cOrder
	Local cPensVer		:= ""
	Local cValidFil		:= fValidFil()
	//Local nRoteir		:= 0
	Local cAliasPENS    := GetNextAlias()
	Local cOrderBy      := ""

	//-- Tratamento para competencia dos benecifiarios
	Local cMesAno		:= ''
	Local dDtIniComp	:= Ctod('')
	Local dDtFimComp	:= Ctod('')
	Local nUltDia		:= 0
	Local nX			:= 0
	//Local aSRQStru
	//-- Tratamento para gera?o de T?ulo de Pens? Aliment?ia por Benefici?io
	Local lGeraTit		:= .T.
	Local cFornAnt		:= cFornec
	Local cLojaAnt		:= cLoja
	Local nOrdRot		:= 1
//	Local nRoteiro		:= 1

	//Variaveis Privates utilizadas em fBuscaLiq()
	Private lImprFunci  := .F. // Indica se deve buscar valores dos funcionarios
	Private lImprBenef  := .T. // Indica se deve buscar valores dos beneficiarios

	Private cArqMovRC   := ""

	Private cAcessaSRA	:= &( " { || " + ChkRH( "GPEM650" , "SRA" , "2" ) + " } " )
	Private cAcessaSRC	:= &( " { || " + ChkRH( "GPEM650" , "SRC" , "2" ) + " } " )
	Private cAcessaSRG	:= &( " { || " + ChkRH( "GPEM650" , "SRG" , "2" ) + " } " )
	Private cAcessaSRH	:= &( " { || " + ChkRH( "GPEM650" , "SRH" , "2" ) + " } " )
	Private cAcessaSRR	:= &( " { || " + ChkRH( "GPEM650" , "SRR" , "2" ) + " } " )
	Private cAcessaSRD	:= &( " { || " + ChkRH( "GPEM650" , "SRD" , "2" ) + " } " )
	Private cCpoDel		:= "D_E_L_E_T_"

	Private dDataDe     := dDataDeT
	Private dDataAte    := dDataAteT
	Private Semana      := "  "
	Private aRoteiros	:= {}

	//-- Tratamento para competencia dos beneficios
	cMesAno  := Substr(cCompetTit,1,2)+"/"+Substr(cCompetTit,3,4)

	dDtIniComp	:= CToD( "01" + "/" + cMesAno )    //Primeiro dia do Mes
	nUltDia	:= f_UltDia( dDtIniComp )      	 //Ultimo dia do Mes
	dDtFimComp	:= CToD(StrZero(nUltDia,2)+"/"+ cMesAno)

	cPensVer := "   "

	If cAgrupa $ "1*4" // Filial*Funcionario
		cOrderBy := "%1,2%"
	ElseIf cAgrupa $ "2*3" //Centro de Custo/Nivel de Centro de Custo
		cOrderBy := "%1,3%"
	EndIf

	BeginSql Alias cAliasPENS
		SELECT DISTINCT
			RA_FILIAL, RA_MAT, RA_CC
		FROM
			%Table:SRA% SRA
			JOIN %Table:SRQ% SRQ ON RQ_FILIAL = RA_FILIAL AND RQ_MAT = RA_MAT
			JOIN %Table:SRC% SRC ON RC_FILIAL = RA_FILIAL AND RC_MAT = RA_MAT
		WHERE
			SRA.%NotDel%
			AND SRQ.%NotDel%
			AND SRC.%NotDel%
			AND RC_PERIODO = %Exp:cAnoMes%
			AND RA_FILIAL >= %Exp:cFilDeT%
			AND RA_FILIAL <= %Exp:cFilAteT%
			AND RA_CC >= %Exp:cCCDeT%
			AND RA_CC <= %Exp:cCCAteT%
			AND RA_MAT >= %Exp:cMatDeT%
			AND RA_MAT <= %Exp:cMatAteT%

		UNION

		SELECT DISTINCT
			RA_FILIAL, RA_MAT, RA_CC
		FROM
			%Table:SRA% SRA
			JOIN %Table:SRQ% SRQ ON RQ_FILIAL = RA_FILIAL AND RQ_MAT = RA_MAT
			JOIN %Table:SRD% SRD ON RD_FILIAL = RA_FILIAL AND RD_MAT = RA_MAT
		WHERE
			SRA.%NotDel%
			AND SRQ.%NotDel%
			AND SRD.%NotDel%
			AND RD_PERIODO = %Exp:cAnoMes%
			AND RA_FILIAL >= %Exp:cFilDeT%
			AND RA_FILIAL <= %Exp:cFilAteT%
			AND RA_CC >= %Exp:cCCDeT%
			AND RA_CC <= %Exp:cCCAteT%
			AND RA_MAT >= %Exp:cMatDeT%
			AND RA_MAT <= %Exp:cMatAteT%

		UNION

		SELECT DISTINCT
			RA_FILIAL, RA_MAT, RA_CC
		FROM
			%Table:SRA% SRA
			JOIN %Table:SRQ% SRQ ON RQ_FILIAL = RA_FILIAL AND RQ_MAT = RA_MAT
			JOIN %Table:SRR% SRR ON RR_FILIAL = RA_FILIAL AND RR_MAT = RA_MAT
		WHERE
			SRA.%NotDel%
			AND SRQ.%NotDel%
			AND SRR.%NotDel%
			AND RR_PERIODO = %Exp:cAnoMes%
			AND RA_FILIAL >= %Exp:cFilDeT%
			AND RA_FILIAL <= %Exp:cFilAteT%
			AND RA_CC >= %Exp:cCCDeT%
			AND RA_CC <= %Exp:cCCAteT%
			AND RA_MAT >= %Exp:cMatDeT%
			AND RA_MAT <= %Exp:cMatAteT%

		ORDER BY
			%Exp:cOrderBy%
	EndSql

	DbSelectArea("SRY")
	("SRY")->( DbGoTop() )
	While !("SRY")->(Eof())
		If SRY->RY_TIPO $ "1*2*3*4*5*6*F"
			If SRY->RY_TIPO == "4"
				Aadd(aRotAux, {SRY->RY_CALCULO, SRY->RY_TIPO, cPensVer,SRY->RY_FILIAL,0 })
			Else
				Aadd(aRotAux, {SRY->RY_CALCULO, SRY->RY_TIPO, cPensVer,SRY->RY_FILIAL,nOrdRot} )
			EndIf
			nOrdRot++
		EndIf
		("SRY")->(DbSkip())
	EndDo

	aSort(aRotAux,,,{|x,y| x[5] < y[5]})
	DbSelectArea("SRA")

	ProcRegua( (cAliasPENS)->(RecCount()) )

	nValTotal  := 0
	cFilialAnt := Replicate("!",FWGETTAMFILIAL)
	cCCAnt     := Replicate("!",GetSx3Cache("RA_CC","X3_TAMANHO"))
	cCpoAgrup  := If(cAgrupa=="1","(cAliasPENS)->RA_FILIAL",If(cAgrupa$"2*3","(cAliasPENS)->RA_CC","(cAliasPENS)->RA_MAT"))

	While (cAliasPENS)->( !Eof() )
		If cAgrupa $ "1*4" // Filial*Funcionario
			SRA->( DbSetOrder(1) )
			SRA->( DbSeek( (cAliasPENS)->(RA_FILIAL+RA_MAT) ) )
		ElseIf cAgrupa $ "2*3" //Centro de Custo/Nivel de Centro de Custo
			SRA->( DbSetOrder(2) )
			SRA->( DbSeek( (cAliasPENS)->(RA_FILIAL+RA_CC+RA_MAT) ) )
		EndIf

		//Verifica quebra de filial e busca novos codigos da folha
		If SRA->RA_FILIAL # cFilialAnt
			//Consiste acesso do usuario a filiais
			If ! ( SRA->RA_FILIAL $ cValidFil )
				SRA->(dbSkip())
				Loop
			EndIf
			IF !FP_CODFOL(@aCodFol,SRA->RA_FILIAL)
				Exit
			Endif
			cFilialAnt := SRA->RA_FILIAL
		Endif

		If cFilRotAux <> xFilial("SRY",SRA->RA_FILIAL)
			cFilRotAux := xFilial("SRY",SRA->RA_FILIAL)
			aRoteiros := {}
			For nX := 1 to Len(aRotAux)
				If cFilRotAux == aRotAux[nX,4]
					Aadd(aRoteiros, {aRotAux[nX,1], aRotAux[nX,2], aRotAux[nX,3]} )
				EndIf
			Next nX
		EndIf

		//Centro de custo para gravacao quando agrupar por funcionario
		If SRA->RA_CC # cCCAnt
			cCCAnt := SRA->RA_CC
		EndIf

		cAgrupAnt := &cCpoAgrup
		While (cAliasPENS)->( !Eof() ) .And. cFilialAnt + cAgrupAnt == (cAliasPENS)->RA_FILIAL + &cCpoAgrup
			IncProc("Gerando Titulos - " + cDescri) //"Gerando Titulos - "

			//Busca os valores do beneficiario
			nValor    := 0
			aValBenef 	:= {}
			dDataRef	:= CTOD("01"+"/"+Substr(cCompetTit,1,2)+"/"+Substr(cCompetTit,3,4) )

			Gp020BuscaLiq(@nValor, @aValBenef, cPensVer,, (cAliasPENS)->RA_FILIAL, (cAliasPENS)->RA_MAT)
			lGeraTit := .F.
			For nCntB := 1 To Len( aValBenef )
				If cGeraBen == "1" .And. cAgrupa == "4"
					lGeraTit := .T.

					If !Empty(aValBenef[nCntB,10]) .And. !Empty(aValBenef[nCntB,11])
						cFornec := aValBenef[nCntB,10]
						cLoja := aValBenef[nCntB,11]
					EndIf

					//Grava o titulo de acordo com seu agrupamento
					aArea :=  (cAliasSRA)->(GetArea())
					If !(U_fGrTit(cFilialAnt,If(cAgrupa$"2*3",cAgrupAnt,If(cAgrupa=="4",cCCAnt,Nil)),If(cAgrupa=="4",cAgrupAnt, Nil),aValBenef[nCntB,5]))
						Exit
					EndIf
					RestArea(aArea)

					cFornec := cFornAnt
					cLoja := cLojaAnt

				Else
					nValTotal += aValBenef[nCntB,5]

					if nValTotal > 0								
						BeginSql Alias "TMPSRD"
							SELECT SRD.R_E_C_N_O_ FROM %TABLE:SRD% SRD 
							WHERE RD_FILIAL=%Exp:(cAliasPENS)->RA_FILIAL%
							AND RD_MAT=%Exp:(cAliasPENS)->RA_MAT%
							AND RD_DTREF=%Exp:DDATABASE%
							AND RD_PD=%Exp:aValBenef[nCntB,4]%
							AND RD_ROTEIR='FOL'
							AND SRD.D_E_L_E_T_ =''		
						EndSql
						//aRet:= GETLastQuery()[2]
												
						WHILE TMPSRD->(!EOF())	
							if ASCAN(aRecTabs,{|x| x==TMPSRD->R_E_C_N_O_ }) == 0
								AADD(aRecTabs,TMPSRD->R_E_C_N_O_)
							endif
						TMPSRD->(dbSkip())
						END

						TMPSRD->(dbCloseArea())				
					Endif					
					
				EndIf
			Next nCntB

			(cAliasPENS)->( DbSkip() )
		EndDo

		//Grava o titulo de acordo com seu agrupamento
		If !lGeraTit
			//Grava o titulo de acordo com seu agrupamento
			aArea :=  (cAliasSRA)->(GetArea())
			If !(U_fGrTit(cFilialAnt,If(cAgrupa$"2*3",cAgrupAnt,If(cAgrupa=="4",cCCAnt,Nil)),If(cAgrupa=="4",cAgrupAnt, Nil),nValTotal))
				Exit
			EndIf
			RestArea(aArea)
		EndIf
		nValTotal := 0
	EndDo

	(cAliasPENS)->( DbCloseArea() )

	DbSelectArea( "SRA" )
	DbSetOrder(1)
	DbSelectArea( cAlias)
Return Nil
/*/{Protheus.doc} fTitUsu
Busca valores no arquivo definido pelo usuario
@author totvs
@since 06/06/2019
@version undefined

@type function
/*/
Static Function fTitUsu(lEnd,lCabec,lVenc)
	Local cAlias		:= ALIAS()
	Local cFilLimI		:= If(Len(Alltrim(cFilAtu)) < FWGETTAMFILIAL, cFilDeT, cFilAtu)
	Local cFilLimF		:= If(Len(Alltrim(cFilAtu)) < FWGETTAMFILIAL, cFilAteT, cFilAtu)
	Local cIniCpo
	Local cPriCpo
	Local cDtFiltro
	Local cIndCond
	Local cFor
	Local cChaveCab
	Local cChaveLan
	Local cChaveBas
	Local aChaveAgrup	:= {}
	Local nRecAgrup		:= 0
	Local nPosAgrup
	Local cChaveAgrup
	Local cModeAccess
	Local cOrder		:= ""
	Local cSelect		:= ""
	Local cPdAux		:= ""
	Local cAliasAux		:= cAliasLan
	Local aAliasStru	:= {}
	Local nX 			:= 0
	Local cValidFil		:= fValidFil()

	DEFAULT lVenc		:= .F.
	Private cArqNtx
	Private cCcLan
	Private cMatLan
	Private cFilLan
	Private cPDLan
	Private cValLan
	Private lMatLan
	Private lCcLan
	Private lMatCab
	Private cCcCab
	Private cItem

//????????????????????????????????
//?Variavel obritatorias do arquivo LANCAMENTOS  		         ?
//????????????????????????????????
	dbSelectArea( cAliasLan )
	cPriCpo := FieldName(1) // Nome do primeiro campo do arquivo
	cIniCpo := Substr(cPriCpo, 1, AT("_", cPriCpo))
	cFilLan := cIniCpo + "FILIAL"
	cCcLan  := cIniCpo + "CC"
	cMatLan := cIniCpo + "MAT"
	cValLan := cIniCpo + If(cAliasLan == "SRZ", "VAL",If (cAliasLan == "SRK","VALORTO","VALOR"))
	cPDLan  := cIniCpo + If(cAliasLan == "SRT", "VERBA", "PD")
	lMatLan := ( FieldPos( cMatLan ) > 0 )
	lCcLan	 := ( FieldPos( cCcLan ) > 0 )
	cItem   := cIniCpo + "ITEM"

//????????????????????????????????
//?Prepara filtro do cadastro de funcionarios       		      ?
//????????????????????????????????
	dbSelectArea( "SRA" )
	dbSetOrder(1)
	cFiltrSRA := AllTrim(cFiltrSRA)

//????????????????????????????????
//?Chave para comparacao entre arquivo CABECALHO E LANCAMENTOS  ?
//????????????????????????????????
	cChaveCab := &( "{ || .T.}" )
	cChaveLan := &( "{ || .T.}" )

	cModeAccess := FWModeAccess( "RC0", 1) + FWModeAccess( "RC0", 2) + FWModeAccess( "RC0", 3)
	If Empty(cFilAtu) .Or. ( !Empty(cFilAtu) .and. cModeAccess <> "EEE")
		cFilLimI := cFilDeT
		cFilLimF := cFilAteT
	Else
		cFilLimI := cFilAtu
		cFilLimF := cFilAtu
	EndIf

	If lCabec

		//????????????????????????????????
		//?Variaveis obritatorias do arquivo CABECALHO    		         ?
		//????????????????????????????????
		dbSelectArea( cAliasCab )
		cPriCpo := FieldName(1) // Nome do primeiro campo do arquivo
		cIniCpo := Substr(cPriCpo, 1, AT("_", cPriCpo))
		cFilCab := cIniCpo + "FILIAL"
		cMatCab := cIniCpo + "MAT"
		lMatCab := ( FieldPos( cMatCab ) > 0 )

		// Tratamento para CC, pois na rescisao (SRG) este campo somente fara parte da tabela de itens (SRR)
		cCcCab	:= If( FieldPos( cIniCpo + "CC" ) > 0, cIniCpo + "CC", "" )

		//????????????????????????????????
		//?Monta indice condicional do arquivo CABECALHO                ?
		//????????????????????????????????
		If cAgrupa == "2" .and. !( cAliasCab $ "SRG*SRH" )   // Centro de Custo/Nivel de Centro de Custo - Cabecalho de Rescisao nao tem CC
			cIndCond := cFilCab + "+" + cCcCab + If(lMatCab, "+" + cMatCab, "")

			cFor := '(' + cFilCab + "+" + cCcCab + If(lMatCab, "+" + cMatCab, "")+;
				' >= "' + cFilLimI+cCCDeT+ If(lMatCab, cMatDeT,'') + '")'

			cFor += ' .And. (' + cFilCab+ "+" + cCcCab + If(lMatCab, "+" + cMatCab, "")+;
				' <= "' + cFilLimF+cCCAteT + If(lMatCab, cMatAteT ,'') + '")'

		Else
			cIndCond := cFilCab + If(lMatCab, "+" + cMatCab, "")

			cFor := '(' + cFilCab + If(lMatCab, "+" + cMatCab, "")+;
				' >= "' + cFilLimI + If(lMatCab, cMatDeT,'') + '")'

			cFor += ' .And. (' + cFilCab + If(lMatCab, "+" + cMatCab, "")+;
				' <= "' + cFilLimF + If(lMatCab, cMatAteT ,'') + '")'

		EndIf

		If !Empty(cFiltrCab)
			cFor += ' .And. ' + AllTrim(cFiltrCab)
		EndIf

		If !Empty(cCpoDtCab)
			cDtFiltro := 'DTOS(' + cCpoDtCab + ')'
			cFor += ' .And. (' +cDtFiltro+' >= "'+DTOS(dDataDeT)+'")'+' .And. ('+cDtFiltro+' <= "'+DTOS(dDataAteT)+'")'
		EndIf

		//????????????????????????????????
		//?Cria indice temporario do arquivo CABECALHO			         ?
		//????????????????????????????????
		cArqNtx := CriaTrab(NIL,.f.)
		IndRegua(cAliasCab,cArqNtx,cIndCond,,cFor,"Selecionando Registros...")  //"Selecionando Registros..."
		dbGoTop()

		//????????????????????????????????
		//?Monta chave para busca das verbas no arquivo de LANCAMENTOS  ?
		//????????????????????????????????
		cTipoItens  := If(cAliasCab == "SRG", "R", If(cAliasCab == "SRH", "F", ""))
		cChaveBas   := "" //Chave basica para busca - somente Filial + Matricula

		If cAliasCab == "SRG"
			cChaveCab := &( "{ || " + cAliasCab + "->" + cFilCab + " + " + cAliasCab + "->" + cMatCab + " + cTipoItens + Dtos(SRG->RG_DTGERAR) }" )
		ElseIf cAliasCab == "SRH"
			cChaveCab := &( "{ || " + cAliasCab + "->" + cFilCab + " + " + cAliasCab + "->" + cMatCab + " + cTipoItens + Dtos(SRH->RH_DATAINI) }" )
		Else
			If cAgrupa == "2"   //Centro de Custo
				cChaveCab := &( "{ || " + cAliasCab + "->" + cFilCab + " + " + cAliasCab + "->" + cCcCab + If(lMatCab, " + " + cAliasCab + "->" + cMatCab,"") + " + Dtos(" + cAliasCab + "->" + cCpoDtRel + ") }" )
				cChaveBas := &( "{ || " + cAliasCab + "->" + cFilCab + " + " + cAliasCab + "->" + cCcCab + If(lMatCab, " + " + cAliasCab + "->" + cMatCab,"") + " }" )
			else
				cChaveCab := &( "{ || " + cAliasCab + "->" + cFilCab + If(lMatCab, " + " + cAliasCab + "->" + cMatCab,"") + " + Dtos(" + cAliasCab + "->" + cCpoDtRel + ") }" )
				cChaveBas := &( "{ || " + cAliasCab + "->" + cFilCab + If(lMatCab, " + " + cAliasCab + "->" + cMatCab,"") + " }" )
			EndIf
		EndIf

		If cAgrupa == "2" .And. cAliasCab != "SRH"   //Centro de Custo
			If 	!Empty(cCpoDtLan)
				cChaveLan := &( "{ || " + cAliasLan + "->" + cFilLan + " + " + cAliasLan + "->" + cCcLan + " + " + cAliasLan + "->" + cMatLan + " + cTipoItens + DTOS(" + cAliasLan + "->" + cCpoDtLan + ") }" )
			Else
				cChaveLan := &( "{ || " + cAliasLan + "->" + cFilLan + " + " + cAliasLan + "->" + cCcLan + " + " + cAliasLan + "->" + cMatLan + " + cTipoItens }" )
			Endif
		else
			If 	!Empty(cCpoDtLan)
				cChaveLan := &( "{ || " + cAliasLan + "->" + cFilLan + " + " + cAliasLan + "->" + cMatLan + " + cTipoItens + DTOS(" + cAliasLan + "->" + cCpoDtLan + ") }" )
			Else
				cChaveLan := &( "{ || " + cAliasLan + "->" + cFilLan + " + " + cAliasLan + "->" + cMatLan + " + cTipoItens }" )
			Endif
		EndIf

		//????????????????????????????????
		//?Processa o arquivo CABECALHO definido pelo usuario		      ?
		//????????????????????????????????
		While !Eof()

			//Consiste acesso do usuario a filiais
			If ! ( (cAliasCab)->&cFilCab $ cValidFil )
				(cAliasCab)->(dbSkip())
				Loop
			EndIf

			dbSelectArea( cAliasLan )
			If dbSeek( If(Empty(cChaveBas), Eval(cChaveCab), Eval(cChaveBas)) )
				dDataVenc := &(cAliasCab + "->" + cCpoDtCab)
				//????????????????????????????????
				//?Efetua tratamento especifico para agrupamento Filial/C.Custo,?
				//?preserva a chave de agrupamento para somar a cada registro.  ?
				//????????????????????????????????
				If cAgrupa # "4"           //Agrupamento Funcionario
					cChaveAgrup := ""
					nRecAgrup   := 0
					If cAgrupa == "1"      //Agrupamento Filial
						cChaveAgrup := &cFilLan + Dtos(dDataVenc)
					ElseIf cAgrupa $ "2*3" //Agrupamento Centro de Custo
						cChaveAgrup := &cFilLan + &cCcLan + Dtos(dDataVenc)
					EndIf
					nPosAgrup := Ascan( aChaveAgrup, { |X| X[1] == cChaveAgrup })
					If nPosAgrup > 0
						nRecAgrup := aChaveAgrup[nPosAgrup, 2]
					Else
						Aadd( aChaveAgrup, { cChaveAgrup, 0 } )
					EndIf
				EndIf

				If cAliasCab $ "SRG*SRH"
					cChaveCab := &( "{ || " + cAliasCab + "->" + cFilCab + If(lMatCab, " + " + cAliasCab + "->" + cMatCab,"") + " + cTipoItens + Dtos(" + cAliasCab + "->" + cCpoDtRel + ") }" )
					While !Eof() .And. !(Eval(cChaveCab) == Eval(cChaveLan))
						DbSkip()
					EndDo
				EndIf

				fProcLctos(cChaveCab, cChaveLan, aChaveAgrup, nRecAgrup)
			EndIf
			dbSelectArea( cAliasCab )
			dbSkip()
		EndDo
	Else
		If cAliasLan <> "RC0"
			aAliasStru 	:= (cAliasLan)->(dbStruct())

			For nX := 1 to Len(cVerbas) Step 4
				If !Empty(cPdAux)
					cPdAux += ","
				EndIf
				cPdAux += "'" + SubStr(cVerbas,nX,3) + "'"
			Next nX

			cSelect := "SELECT * " + CRLF
			cQuery := "FROM " + RetSqlName(cAliasLan) + CRLF
			cQuery += "WHERE " + cFilLan +	" BETWEEN '" + cFilLimI + "' AND '" + cFilLimF	+ "' AND "

			If lMatLan
				cQuery += cMatLan + " BETWEEN '" + cMatDeT + "' AND '" + cMatAteT	+ "' AND "
			EndIf

			If lCcLan
				cQuery += cCcLan + " BETWEEN '" + cCcDeT  + "' AND '" + cCcAteT	+ "' AND "
			EndIf

			/*If cAliasLan == "SRD" .and. !Empty(cAnoMes)
				cQuery += "RD_DATARQ = '" + cAnoMes + "' AND "
			EndIf*/

			If !Empty(cCpoDtLan)
				//cQuery += " " + cCpoDtLan + " BETWEEN '" + Dtos(dDataDeT) + "' AND '" + Dtos(dDataAteT) + "' AND "
				cQuery += " " + cCpoDtLan + " = '" + Dtos(dDataDeT) + "' AND "
			EndIf

			If !( Empty(cPdAux) )
				cQuery += cPDLan + " IN ( " + cPdAux + " ) AND "
			Else
				cQuery += cPDLan + " IN ('') AND "
			EndIf

			if IsInCallStack("U_CFINA94")

				cQuery += " RD_XCNABIN = 'X' AND "

			endif

			cQuery += "D_E_L_E_T_ = ' ' "

			cOrder := " ORDER BY "

			If cAgrupa $ "1*4"       // Filial*Funcionario
				cOrder += cFilLan + If(lMatLan, "," + cMatLan, "") + If(lCcLan,"," + cCcLan, "") + CRLF
			ElseIf cAgrupa $ "2*3"   //Centro de Custo/Nivel de Centro de Custo
				cOrder += cFilLan + "," + cCcLan + If(lMatLan, "," + cMatLan, "") + CRLF
			EndIf

			cQuery := ChangeQuery(cSelect+cQuery+cOrder)
			cAliasLan 	:= GetNextAlias()

			//ABRE A EXECUCAO DA QUERY ATRIBUIDA AO SRA
			If MsOpenDbf(.T.,"TOPCONN",TcGenQry(, ,cQuery),cAliasLan,.F.,.T., .F. , .F.)
				For nX := 1 To Len(aAliasStru)
					If !( aAliasStru[ nX , 02 ] == "C" )
						TcSetField(cAliasLan,aAliasStru[nX][1],aAliasStru[nX][2],aAliasStru[nX][3],aAliasStru[nX][4])
					EndIf
				Next nX
			EndIf
		EndIf

		If cAliasLan <> "RC0"
			fProcLctos(cChaveCab, cChaveLan,,,cAliasAux,cFiltrLan,lVenc)
		EndIf
	EndIf

	(cAliasLan)->(DbCloseArea())
	dbSelectArea(cAlias)

Return Nil
/*/{Protheus.doc} ProcLctos
Busca valores no arquivo de Intes definido pelo usuario
@author totvs
@since 06/06/2019
@version undefined

@type function
/*/
Static Function fProcLctos(cChaveCab,cChaveLan,aChaveAgrup,nRecAgrup,cAliasAux,cFiltrLan,lVenc)
	Local cAlias    := ALIAS()
	Local cTipVerba
	Local nValTitulo 	:= 0
	Local cFilialAnt
	Local cCCAnt
	Local cAgrupAnt
	Local cCpoAgrup  	:= If(cAgrupa == "1", cFilLan, If(cAgrupa $ "2*3", cCcLan, cMatLan))
	Local lIRRF			:= .F.
	Local lRatItm		:= SuperGetMV("MV_RATITM",,.F.)
	Local aDetTitulo	:= {}

	DEFAULT cAliasAux	:= cAliasLan
	DEFAULT cFiltrLan	:= ""
	DEFAULT lVenc		:= .F.

	cFilialAnt := Replicate("!",FWGETTAMFILIAL)
	cCCAnt     := Replicate("!", GetSx3Cache("RA_CC", "X3_TAMANHO"))

	If lVenc .And. Empty(dVctoInf)
		dDataVenc := ctod("  /  /  ")
	EndIf

	While !Eof() .And. Eval(cChaveCab) == Eval(cChaveLan)
		cFilialAnt    	:= &cFilLan
		cAgrupAnt     	:= &cCpoAgrup
		aAliasFields	:= {}
		aDetTitulo		:= {}
		aRecTabs		:= {}

		If lVenc .And. Empty(dDataVenc)
			dDataVenc := &(cAliasLan + "->" + cCpoDtCab)
		EndIf

		While !Eof() .And. cFilialAnt + cAgrupAnt == &cFilLan + &cCpoAgrup

			//????????????????????????????????
			//?Verifica se satisfaz a condicao do arquivo de Cabecalho    	?
			//????????????????????????????????
			If Eval(cChaveCab) # Eval(cChaveLan)
				Exit
			EndIf

			If !Empty(cFiltrLan)
				(cAliasAux)->( dbGoTo( (cAliasLan)->R_E_C_N_O_ ) )
				If !&cFiltrLan
					dbSelectArea( cAliasLan )
					dbSkip()
					Loop
				EndIf
			EndIf

			//????????????????????????????????
			//?Centro de custo para gravacao quando agrupar por funcionario ?
			//????????????????????????????????
			If &cCcLan # cCCAnt
				cCCAnt := &cCcLan
			EndIf

			//????????????????????????????????
			//?Testa o filtro do cadastro de funcionarios                   ?
			//????????????????????????????????
			If cFiltrSRA # Nil .And. !Empty(cFiltrSRA)
				cChaveBusca := &cFilLan + &cMatLan
				dbSelectArea( "SRA" )
				If dbSeek( cChaveBusca )
					If !&cFiltrSRA
						dbSelectArea( cAliasLan )
						dbSkip()
						Loop
					EndIf
				EndIf
				dbSelectArea( cAliasLan )
			EndIf

			//????????????????????????????????
			//?Verifica se as verbas existem no arquivo em processamento    ?
			//????????????????????????????????
			If &cPDLan $ cVerbas
				cTipVerba := Substr( cVerbas, AT(&cPDLan, cVerbas)+3, 1)
				PosSrv(&cPDLan,&cFilLan)
				lIRRF	:=	.F.
				If ( SRV->RV_CODFOL == '0152' )
					lIRRF	:=	.T.
				EndIf
				dbSelectArea( cAliasLan )
				If !(cTipVerba $ "P*D")
					cTipVerba := If(SRV->RV_TIPOCOD == "2", "D", "P")
				EndIf
				If cTipVerba == "P"     // Verbas definidas (No Titulo) pelo usuario como provento
					nValTitulo += &cValLan
					If lRatItm
						fSomaRat( &cValLan, &cItem )
					EndIf
				ElseIf cTipVerba == "D" //Verbas definidas (No Titulo) pelo usuario como desconto
					nValTitulo -= &cValLan
					If lRatItm
						fSomaRat( (&cValLan)*(-1), &cItem )
					EndIf
				EndIf

				If cAliasAux == "SRR" .AND. RR_ROTEIR == "RES"
					aAdd(aDetTitulo,{RR_FILIAL,RR_MAT,RR_DATA,RR_PERIODO,RR_SEMANA})
				EndIf

				AADD(aRecTabs,(cAliasLan)->R_E_C_N_O_)

			EndIf
			dbSelectArea(cAliasLan)
			dbSkip()
		EndDo
		//????????????????????????????????
		//?Grava o titulo de acordo com seu agrupamento                 ?
		//????????????????????????????????
		If !(u_fGrTit(cFilialAnt,If(cAgrupa$"2*3",cAgrupAnt,If(cAgrupa=="4",cCCAnt,Nil)),If(cAgrupa=="4",cAgrupAnt, Nil),nValTitulo,aChaveAgrup,nRecAgrup,cAliasAux,aDetTitulo))
			Exit
		EndIf
		nValTitulo := 0
	EndDo
	dbSelectArea(cAlias)

Return Nil

/*/{Protheus.doc} fGrTit
Grava os valores gerados no arquivo de titulos
@author  totvs
@since   13/08/2001
@version 1.0
/*/
User Function fGrTit(cFilGrav, cCCGrav, cMatGrav, nValTit, aChaveAgrup, nRecAgrup, cAliasAux, aChaveDet)
	Local cAlias     := Alias()
	Local cFilAux    := cFilAnt
	Local cCposRC1
	Local nCnt1
	Local dDataAux
	Local aAreaSRA   := SRA->( GetArea() )
	Local aAreaSRZ   := SRZ->( GetArea() )
	Local aAreaAux	 := {}

	Local aDadosAuto := {} // Array para o cadastro de fornecedores via ExecAuto
	//Local aDadosPE   := {} // Array de retorno para o PE GP650CFO
	//Local nOpc 		 := 0
	Local aErro 	 := {}
	Local cLog 	  	 := ""
	Local aLogCampo  := {}
	Local nI 		 := 0
	Local cPeriodo   := ""
	Local lGeraRJ1   := .F.
	Local nPosFor	 := 0
	Local nPosLoj 	 := 0
	Local cCodSA2    := ""
	Local aIdsFol	 := {}
	Local cIdsFol	 := ""
	Local nXr		 := 0

	Private nVlTotTit  := nValTit
	Private cCpoFornec := cFornec
	Private cNovoTit

	//Variáeis declaradas para a execução da MSExecAuto
	Private lMsErroAuto    := .F.
	Private lMsHelpAuto    := .T.
	Private lAutoErrNoFile := .T.

	Static cValidFil	:= fValidFil()
	Static lCadForA 	:= SuperGetMv( 'MV_CADFORA', .F., .F., cFilAnt )

	DEFAULT cAliasAux := cAliasLan
	DEFAULT aChaveDet := {}

	If cAliasAux == "SRR" .And. lTamTitDif .And. lMsgRJ1
		lMsgRJ1 := .F.
	ElseIf cAliasAux == "SRR"
		lGeraRJ1 := !lTamTitDif
	EndIf

//Variaveis utilizadas para agrupamento Filial/C.Custo quando o usuario definir Data de Vencimento pelo arquivo de CABECALHO
	aChaveAgrup := If( aChaveAgrup == Nil, {}, aChaveAgrup )
	nRecAgrup   := If( nRecAgrup   == Nil, 0,  nRecAgrup   )

	If !( cFilGrav $ cValidFil )
		If !lTitLog3
			aAdd(aLogFile,{5,OemToAnsi("STR0046") + CRLF}) // Os t?ulos que seguem n? foram gerados pois o usu?io n? tem acesso as filiais dos mesmos:
			lTitLog3 := .T.
		EndIf

		aAdd(aLogFile,{6,""})

		If !Empty(cFilGrav)
			aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0024") + cFilGrav )
		Endif
		If !Empty(cCCGrav)
			aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0025") + cCCGrav )
		Endif
		If !Empty(cMatGrav)
			aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0026") + cMatGrav )
		Endif
		aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0027") + cPrefix )
		aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0028") + cIdentTit )

		Return .T.
	EndIf

	If cAliasAux # Nil .And. !Empty(cAliasAux)
		aAreaAux	:= (cAliasAux)->(GetArea())
	EndIf

	If cAgrupa == "4"
		DbSelectArea( cAliasAux )

		If cAliasAux == "SRR" .And. !Empty(cCpoDtCab)
			SRR->( DbSetOrder(4) )
			cPeriodo := SubStr(cCompetTit,3,4) + SubStr(cCompetTit,1,2)
		EndIf

		If DbSeek( cFilGrav + cMatGrav + cPeriodo )
			If ( !Empty(cAliasCab) .and. !Empty(cCpoDtCab) )
				dDataVenc := &(cAliasCab + "->" + cCpoDtCab)
			EndIf
		ElseIf !Empty(cPeriodo)
			If DbSeek( cFilGrav + cMatGrav )
				If ( !Empty(cAliasCab) .and. !Empty(cCpoDtCab) )
					dDataVenc := &(cAliasCab + "->" + cCpoDtCab)
				EndIf
			EndIf
		EndIf
	EndIf

	dDataVenc := If( !Empty(dVctoInf),dVctoInf,dDataVenc)
	dDataAux  := DataValida(dDataVenc,If(cdiaUtil =="1",.F.,.T.)) // Vencimento real
	dDataVenc := If(dDataAux < dDataVenc,dDataAux,dDataVenc)      // Vencimento

	If lConsiste
		If fExistTit(xFilial("RC1", cFilGrav ),cPrefix,cIdentTit,cFilGrav,cCCGrav,cMatGrav,cAgrupa,cCompetTit,nVlTotTit,dDataVenc)
			If Len(aAreaAux) > 0
				RestArea( aAreaAux )
			EndIf

			Return .T.
		EndIf
	EndIf

	If !Empty(cFilGrav) .And. nVlTotTit > 0
		//Verifica se Fornecedor foi preenchido com campo de arquivo
		If "_" $ cFornec
			cCpoFornec := ""
			If cAgrupa $ "2*3" .And. cCCGrav # Nil
				dbSelectArea( cAliasCC )
				dbSeek( xFilial(cAliasCC) + cCCGrav )
				cCpoFornec := &( cAliasCC + "->" + AllTrim(cFornec) )
			ElseIf cAgrupa == "4" .And. cMatGrav # Nil
				dbSelectArea( "SRA" )
				dbSeek( cFilGrav + cMatGrav )
				cCpoFornec := &( "SRA->" + AllTrim(cFornec) )
				If lCadForA
					DbSelectArea( "RDZ" )
					RDZ->(DbSetOrder(1)) //RDZ_FILIAL+RDZ_EMPENT+RDZ_FILENT+RDZ_ENTIDA+RDZ_CODENT+RDZ_CODRD0
					If (RDZ->(MsSeek(xFilial("RDZ") + cEmpAnt + xFilial("SRA",SRA->RA_FILIAL) + "SRA" + cFilGrav + cMatGrav)))
						DbSelectArea( "RD0" )
						RD0->(DbSetOrder(1)) //RD0_FILIAL+RD0_CODIGO
						If (RD0->(MsSeek(xFilial("RD0") + RDZ->RDZ_CODRD0)))
							//Incluir os dados na aDadosAuto para grava?o na SA2 via ExecAuto
							DbSelectArea( "SA2" )
							SA2->(DbSetOrder(1)) //A2_FILIAL+A2_COD+A2_LOJA

							If (Empty(RD0->RD0_FORNEC + RD0->RD0_LOJA))
								//Verifica se o fornecedor existe na SA2
								If SA2->(MsSeek(xFilial("SA2") + &( "SRA->" + AllTrim(cFornec) )))
									If Empty( cCodSA2 := CriaVar("A2_COD") )
										cCpoFornec := GetSx8Num("SA2","A2_COD",,)
									Else
										cCpoFornec := cCodSA2
										If __lSx8
											RollBackSX8()
										EndIf
									EndIf
								EndIf

								//Tratamento de campos que ser? enviados da SRA para SA2
								Aadd( aDadosAuto, {'A2_COD'		, cCpoFornec , NIL} )
								Aadd( aDadosAuto, {'A2_LOJA' 	, cLoja , Nil} )
								Aadd( aDadosAuto, {'A2_NOME'	, If(TamSX3( 'RA_NOME' )[1] > TamSX3( 'A2_NOME' )[1], Substr(SRA->RA_NOME , 1 , TamSX3( 'A2_NOME' )[1] ) , SRA->RA_NOME ) , Nil} )
								Aadd( aDadosAuto, {'A2_NREDUZ'	, If(TamSX3( 'RA_NOME' )[1] > TamSX3( 'A2_NREDUZ' )[1], Substr(SRA->RA_NOME , 1 , TamSX3( 'A2_NREDUZ' )[1] ) , SRA->RA_NOME ) , Nil} )
								If !Empty(SRA->RA_ENDEREC)
									Aadd( aDadosAuto, {'A2_END' , If(TamSX3( 'RA_ENDEREC' )[1] > TamSX3( 'A2_END' )[1], Substr(SRA->RA_ENDEREC , 1 , TamSX3( 'A2_END' )[1] ) , SRA->RA_ENDEREC ) , Nil} )
								Else
									Aadd( aLogCampo, "SRA->RA_ENDEREC")
								Endif
								If !Empty(SRA->RA_ESTADO)
									Aadd( aDadosAuto, {'A2_EST' , If(TamSX3( 'RA_ESTADO' )[1] > TamSX3( 'A2_EST' )[1], Substr(SRA->RA_ESTADO , 1 , TamSX3( 'A2_EST' ) )[1] , SRA->RA_ESTADO ) , Nil} )
								Else
									Aadd( aLogCampo, "SRA->RA_ESTADO")
								Endif
								If !Empty(SRA->RA_MUNICIP)
									Aadd ( aDadosAuto, {'A2_MUN' , If(TamSX3( 'RA_MUNICIP' )[1] > TamSX3( 'A2_MUN' )[1], Substr(SRA->RA_MUNICIP , 1 , TamSX3( 'A2_MUN'  )[1] ) , SRA->RA_MUNICIP ) , Nil} )
								Else
									Aadd( aLogCampo, "SRA->RA_MUNICIP")
								Endif
								Aadd( aDadosAuto, {'A2_TIPO' , 'F' , Nil} )
								Aadd( aDadosAuto, {'A2_CGC' , SRA->RA_CIC , Nil} )
								Aadd( aDadosAuto, {'A2_BAIRRO' , If(TamSX3( 'RA_BAIRRO' )[1] > TamSX3( 'A2_BAIRRO' )[1], Substr(SRA->RA_BAIRRO , 1 , TamSX3( 'A2_BAIRRO'  )[1] ) , SRA->RA_BAIRRO ) , Nil} )

								If Len(aLogCampo) > 0
									aAdd(aLogFile,{3,OemToAnsi("STR0035")}) // Os funcion?ios abaixo n? foram cadastrados como fornecedores
									aAdd(aLogFile,{4,"",""})
									aLogFile[Len(aLogFile),2] += "STR0033" + SRA->RA_FILIAL + SRA->RA_MAT + "STR0037"
									aLogFile[Len(aLogFile),3] += "  necess?io que os campos do funcion?io estejam preenchidos:" + CRLF
									For nCnt1:=1 to Len( aLogCampo )
										aLogFile[Len(aLogFile),3] += aLogCampo[nCnt1] + " / "
									Next nCnt1
									Return .T.
								Endif

								//Cadastra um novo Fornecedor
								MSExecAuto({|x, y| MATA020(x, y)},aDadosAuto, 3)

								If !lMsErroAuto
									nPosFor := Ascan(aDadosAuto, { |x|  Upper(x[1]) == "A2_COD" })
									nPosLoj := Ascan(aDadosAuto, { |x|  Upper(x[1]) == "A2_LOJA"})

									If nPosFor > 0 .AND. nPosLoj > 0
										RecLock("RD0",.F.)
										RD0->RD0_FORNEC := aDadosAuto[nPosFor,2]	//SA2->A2_COD
										RD0->RD0_LOJA 	:= aDadosAuto[nPosLoj,2]	//SA2->A2_LOJA
										RD0->(MsUnlock())
									Endif

									ConfirmSX8()
								Else
									If Empty(cCodSA2)
										RollBackSX8()
									EndIf
									aErro := GetAutoGRLog()
									VarInfo("STR0036",aErro)

									For nI := 1 To Len(aErro)
										cLog += StrTran( StrTran( StrTran( StrTran( StrTran( aErro[nI], CHR(10), " " ), CHR(13), " " ), "/", "" ), "<", "" ), ">", "" ) + "|"
									Next nI

									If !lTitLog2
										aAdd(aLogFile,{3,OemToAnsi("STR0035") + CRLF}) // Os funcion?ios abaixo n? foram cadastrados como fornecedores
										lTitLog2 := .T.
									EndIf

									aAdd(aLogFile,{4,"",""})
									aLogFile[Len(aLogFile),2] += "STR0033" + SRA->RA_FILIAL + SRA->RA_MAT + "STR0037"

									aLogFile[Len(aLogFile),3] += cLog

									SA2->(DbCloseArea())
									RD0->(DbCloseArea())
									SRA->(DbCloseArea())

									Return .T.
								EndIf
							EndIf
							SA2->(DbCloseArea())
							cCpoFornec := RD0->RD0_FORNEC
							cLoja      := RD0->RD0_LOJA
						EndIf
						RD0->(DbCloseArea())
					Else
						If !lTitLog2
							aAdd(aLogFile,{3,OemToAnsi("STR0035") + CRLF}) // Os funcion?ios abaixo n? foram cadastrados como fornecedores
							lTitLog2 := .T.
						EndIf

						aAdd(aLogFile,{4,""})
						aLogFile[Len(aLogFile),2]+= "STR0033" + cFilGrav + cMatGrav + "STR0034" //O funcion?io n? pode ser cadastrado pois n? possui v?culo na RDZ + CRLF

						RDZ->(DbCloseArea())
						Return .T.
					EndIf
					RDZ->(DbCloseArea())
				EndIf
			EndIf
		EndIf

		//Posiciona cFilAnt na filial corrente p/ garantir Integridade
		cFilAnt := cFilGrav

		cNovoTit := GetSx8Num("RC1","RC1_NUMTIT",,RetOrdem( "RC1" , "RC1_FILIAL+RC1_NUMTIT" ))

		DbSelectArea( "RC1" )

		Begin Transaction
			If nRecAgrup > 0
				dbGoTo( nRecAgrup )
				RecLock("RC1",.F.,.F.)
				RC1->RC1_VALOR += nVlTotTit
				MsUnLock()
			Else
				//Novo numero do titulo deve ser antes do Reclock devido a integridade
				RecLock("RC1",.T.,.T.)
				RC1->RC1_FILIAL   := xFilial("RC1", cFilGrav )
				RC1->RC1_INTEGR   := "0"
				RC1->RC1_FILTIT   := cFilGrav
				If cCCGrav # Nil .and. cAgrupa # "1"
					RC1->RC1_CC := cCCGrav
				EndIf
				If cMatGrav # Nil
					RC1->RC1_MAT := cMatGrav
				EndIf

				//Tratamento de Integra?o Logix x Rh Protheus
				If cpaisloc == "BRA"
					If lRc1Arelin
						fGravArelin( cMatGrav )
					EndIf
				EndIf

				RC1->RC1_CODTIT   := cCodTit
				RC1->RC1_DESCRI   := cDescri
				RC1->RC1_PREFIX   := cPrefix
				RC1->RC1_NUMTIT   := cNovoTit
				RC1->RC1_TIPO     := cIdentTit
				RC1->RC1_NATURE   := cNature
				RC1->RC1_FORNEC   := cCpoFornec
				RC1->RC1_LOJA	  := cLoja
				RC1->RC1_EMISSA   := dDtEmisTit
				RC1->RC1_VENCTO   := dDataVenc
				RC1->RC1_VENREA   := dDataAux
				RC1->RC1_VALOR    := nVlTotTit
				RC1->RC1_DTBUSI   := dDataDeT
				RC1->RC1_DTBUSF   := dDataAteT
				RC1->RC1_COMPET   := cCompetTit

				If cpaisloc == "BRA"
					If cTipoRet <> "2"
						RC1->RC1_CODRET := cCodRetTit
					Else
						RC1->RC1_CODRET := cSRACodRet
					EndIf
				EndIf

				//Grava os campos criados pelo usuario - do RC0 para o RC1
				For nCnt1 := 1 To Len(aCposUsu)
					cCposRC1  := aCposUsu[nCnt1,2]
					&cCposRC1 := aCposUsu[nCnt1,3]
				Next nCnt1

				//Grava no array o numero do recno para agrupar posteriormente
				If Len(aChaveAgrup ) > 0
					aChaveAgrup[Len(aChaveAgrup),2] := Recno()
				EndIf

				RC1->( MsUnLock() )

				ConfirmSX8()
			EndIf

			If lGeraRJ1
				fGrvTitCal(aChaveDet)
			EndIf

			SX3->(DbSetOrder(2))

			//Gravacao dos valores do Titulo agrupados por Item Contabil.
			//ColumnPos() - Retirar essa valida?o do campo QF_FILTIT a partir do release 12.1.18
			If SX3->( DbSeek("QF_FILTIT") ) //se campo existe realiza gravacao
				For nI := 1 to Len(aRatTit)
					RecLock("SQF",.T.)
					SQF->QF_FILIAL := xFilial("SQF",cFilGrav)
					SQF->QF_FILTIT := cFilGrav
					SQF->QF_NUMTIT := cNovoTit
					SQF->QF_ITEM   := aRatTit[nI][1]
					SQF->QF_VALOR  := aRatTit[nI][2]
					MsUnLock()
				Next nI

				aRatTit := {}
			EndIf

			//Grava numero do titulo na tabela para não processar novamente
			For nXr:=1 to len(aRecTabs)
				If cAliasAux == "SRD"

					SRD->(dbgoto(aRecTabs[nXr]))

					RECLOCK("SRD",.F.)
					if IsInCallStack("U_CFINA94")
						if _cTpCNAB == "CN"
							SRD->RD_XCNABIN := "" //CNAB INCONSISTENCIA
						else
							SRD->RD_XCNABOP := "" //CNAB ORDEM PAGTO
						endif
						SRD->RD_XOCORRE := ""
						SRD->RD_XPROCBX := ""
						SRD->RD_XDTEFET := STOD(space(8))
						SRD->RD_XSOCOR  := ""
					endif

					SRD->RD_XNUMTIT:= RC1->RC1_NUMTIT

					MSUNLOCK()

					IF ASCAN(aIdsFol,{|x| x[1]==SRD->RD_XIDFOL }) == 0
						AADD(aIdsFol,{SRD->RD_XIDFOL,SRD->RD_ROTEIR})
					ENDIF

				ENDIF
			next

			//Tratamento do login de rede
			IF !EMPTY(aIdsFol)

				aEval(aIdsFol,{|x| cIdsFol+=x[1]+"|" })

				dbSelectArea("ZC7")
				ZC7->(dbSetOrder(1))
				ZC7->(dbSeek(aIdsFol[1][1])) //Posiciona pelo primeiro id folha

				RecLock("RC1",.F.)
				RC1->RC1_XLREDE:= ZC7->ZC7_LGREDE
				RC1->RC1_XROTEI:= aIdsFol[1][2]
				RC1->RC1_XIDFOL:= cIdsFol
				MsUnlock()
			ENDIF

		End Transaction

		//Retorna filial original para o cFilAnt
		cFilAnt := cFilAux
	EndIf

	RestArea( aAreaSRA )
	RestArea( aAreaSRZ )

	If Len(aAreaAux) > 0
		RestArea( aAreaAux )
	EndIf

	DbSelectArea( cAlias )

Return .T.

/*
???????????????????????????????????????
???????????????????????????????????????
? ?????????????????????????????????????
??rograma  ?GravArelin  ?utor  ?iago Malta      ?Data ? 10/09/09   ??
???????????????????????????????????????
??esc.     ?ntegra?o Logix X Rh Protheus.                  		  ??
???????????????????????????????????????
??so       ?                                                           ??
???????????????????????????????????????
???????????????????????????????????????
???????????????????????????????????????
*/
Static Function fGravArelin( cMat )

	Local cDepto  := space(10)
	Local cArelin := space(10)

	IF cMat <> nil .AND. !EMPTY(cMat) .AND. Getmv("MV_ERPLOGI") == '1'

		SRA->( dbSetOrder(1) )
		SRA->( dbSeek( xFilial('SRA') + cMat ) )
		cDepto := SRA->RA_DEPTO

		SQB->( dbSetOrder(1) )
		SQB->( dbSeek( xFilial('SQB') + cDepto ) )
		cArelin := SQB->QB_ARELIN

		IF !EMPTY(cArelin)
			RC1->RC1_ARELIN := cArelin
		ENDIF

	ENDIF

Return()

/*/{Protheus.doc} fExistTit
Verifica se o t?ulo j?foi gerado
@author  gabriel.almeida
@since   17/07/2015
@param   cFil = Filial vinda da RC0
@param   cPrex = Prefixo vindo da RC0
@param   cTipoT = Tipo do t?ulo vindo da RC0
@param   cFilt = Filial do t?ulo vindo da RC0
@param   cCC = Centro de custo vindo da RC0
@param   cMat = Matr?ula vinda da RC0
@param   cAgrup = Agrupamento
@param   cCompet = Compet?cia do t?ulo
@param   nValor = Valor do t?ulo
@param   dDtVenc = Data de vencimento do t?ulo
/*/
Static Function fExistTit(cFil,cPrex,cTipoT,cFilT,cCC,cMat,cAgrup,cCompet,nValor,dDtVenc)
	Local lRet      := .F.
	Local aArea     := GetArea()
	Local cArqRC1   := CriaTrab( "", .F. )
	Local nIndex    := 0
	Local cIndex    := ""
	Local nTam1     := TamSX3("RC1_VALOR")[1]
	Local nTam2     := TamSX3("RC1_VALOR")[2]
	Local cDataVen  := ""

	Do Case
	Case cAgrup == "1" //Filial
		cIndex := "RC1_FILIAL+RC1_PREFIX+RC1_TIPO+RC1_COMPET+Str(RC1_VALOR,nTam1,nTam2)+RC1_FILTIT"
		cMat   := ""
		cCC    := ""
	Case cAgrup $ "2/3" //Centro de Custo
		cIndex := "RC1_FILIAL+RC1_PREFIX+RC1_TIPO+RC1_COMPET+Str(RC1_VALOR,nTam1,nTam2)+RC1_CC"
		cMat   := ""
		cFilT  := ""
	Case cAgrup == "4" //Matr?ula
		cIndex := "RC1_FILIAL+RC1_PREFIX+RC1_TIPO+RC1_COMPET+Str(RC1_VALOR,nTam1,nTam2)+RC1_MAT"
		cFilT  := ""
		cCC    := ""
	EndCase

	If cChaveDup == "2" //Inclu?a data de vencimento na chave
		cIndex   += "+DTOS(RC1_VENCTO)"
		cDataVen := DToS(dDtVenc)
	EndIf

	RC1->(IndRegua( "RC1", cArqRC1, cIndex, NIL, NIL, NIL, .F.))
	nIndex := RetIndex( "RC1" ) + 1
	RC1->( DbSetOrder( nIndex ) )

	cTipoT := cTipoT + Space(TamSX3("RC1_TIPO")[1]-Len(cTipoT))

	If RC1->( MsSeek( cFil+cPrex+cTipoT+cCompet+Str(nValor,nTam1,nTam2)+cFilT+cCC+cMat+cDataVen ) )
		lRet := .T.

		If !lTitLog1
			// O valor 1 na primeira posi?o do array representa o Log de duplicidade de t?ulos
			aAdd(aLogFile,{1,OemToAnsi("STR0023") + CRLF})
			lTitLog1 := .T.
		EndIf
		aAdd(aLogFile,{2})
		If !Empty(cFilT)
			aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0024") + cFilT )
		EndIf
		If !Empty(cCC)
			aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0025") + cCC )
		EndIf
		If !Empty(cMat)
			aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0025") + cCC )
		EndIf
		aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0027") + cPrex )
		aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0028") + cTipoT )
		aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0029") + cCompet )
		If !Empty(cDataVen)
			aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0048") + DToC(dDtVenc) )
		EndIf
		aAdd( aLogFile[Len(aLogFile)], OemToAnsi("STR0030") + Alltrim(Transform(nValor,"@E 9,999,999,999,999.99")) )
	EndIf

	RestArea(aArea)
Return lRet

/*/{Protheus.doc} fSomaRat
Funcao responsavel em alimentar array aRatTit que guarda valor do titulo rateado por Item Contabil.
@author esther.viveiro
@since 14/08/2017
@version P12
@param nValor, numerico, valor rateado
@param cItem, caractere, codigo do Item Contabil referente ao valor enviado.
@return Nil
/*/
Static Function fSomaRat(nValor, cItem)
	If ( ValType(aRatTit) == "A" )
		nPosItem := aScan(aRatTit,{|aBusca| aBusca[1] == cItem})
		If nPosItem > 0 //encontrou Item no array
			aRatTit[nPosItem][2] += nValor
		Else
			aadd(aRatTit,{cItem,nValor})
		EndIf
	EndIf
Return Nil
/*/{Protheus.doc} fGrvTitCal
//Grava os detalhes do titulo 
@author paulo.inzonha
@since 24/01/2019
@version 1.0
@return Logico
@type function
/*/
Static Function fGrvTitCal(aChaveDet)
	Local nX := 0

	If TCCanOpen(RetSqlname("RJ1")) .AND. LEN(aChaveDet) > 0
		dbSelectArea( "RJ1" )
		For nX := 1 To Len(aChaveDet)
			RecLock("RJ1",.T.)
			RJ1->RJ1_FILIAL := RC1->RC1_FILTIT
			RJ1->RJ1_CODTIT := RC1->RC1_CODTIT
			RJ1->RJ1_PREFIX	:= RC1->RC1_PREFIX
			RJ1->RJ1_NUMTIT := RC1->RC1_NUMTIT

			RJ1->RJ1_FILFUN := aChaveDet[nX,1]
			RJ1->RJ1_MAT	:= aChaveDet[nX,2]
			RJ1->RJ1_DTGERA := aChaveDet[nX,3]
			RJ1->RJ1_PERIOD := aChaveDet[nX,4]
			RJ1->RJ1_SEMANA := aChaveDet[nX,5]
			RJ1->( MsUnLock() )
		Next nX
		dbCloseArea( "RJ1" )
	EndIf

Return .T.
/*/{Protheus.doc} CJBK03RS
Relatório sintético bolsa auxilio
@author Carlos Henrique
@since 27/04/2020
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User Function CJBK03RS()

	Local lXpensao	:= U_TITPENSAO()	//Verifica se o Titulo é de Pagamento de Pensão
	Local cTmpPath 	:= GetTempPath()
	Local cNomeRel	:= "SINTETICO_PAGAMENTO_DE_BOLSA_AUXILIO_" + ALLTRIM(RC1->RC1_NUMTIT)
	Local cDirRel	:= ""
	Local lApur     := IsInCallStack("U_CFINA97")

	Private cPictVrl:= PESQPICT("RC1","RC1_VALOR")


	If lXpensao
		cNomeRel:= "SINTETICO_PAGAMENTO_DE_PENSAO_" + ALLTRIM(RC1->RC1_NUMTIT)
	Endif
	
	If lApur
		If !lXpensao
			cNomeRel:= "CONFERENCIA_APURACAO_IR_BOLSA_AUXILIO_" + ALLTRIM(RC1->RC1_NUMTIT)
		Else
			cNomeRel:= "CONFERENCIA_APURACAO_IR_PENSAO_" + ALLTRIM(RC1->RC1_NUMTIT)
		Endif
	EndIf

	IF CJBK03RE(RC1->RC1_NUMTIT,ALLTRIM(RC1->RC1_DESCRI),RC1->RC1_VENREA,@cNomeRel,@cDirRel,RC1->RC1_TIPO,RC1->RC1_CODTIT)

		FERASE(cTmpPath+cNomeRel)
		CpyS2T(cDirRel, cTmpPath , .F. )

		IF FILE(cTmpPath+cNomeRel)
			ShellExecute("OPEN",cTmpPath+cNomeRel,"","",5)
		ELSE
			MSGALERT("Não foi possível realizar a cópia do relatório para o diretório:" + CRLF + cTmpPath)
		ENDIF

	ELSE
		If !lApur
			MSGALERT("Não foi possível gerar o relatório, contate o administrador do sistema!!")
		EndIf
	ENDIF

Return

/*/{Protheus.doc} CJBK03Tot
//Retorna valor total de IR
@author andre.brito
@since 11/07/2020
@version 1.0
@Return ${Return}, ${Return_description}
@param cPerg, characters, descricao
@type function
/*/

Static Function CJBK03Tot(cIDFOL,cMatr,cCompet,cVerba)

	local nRet   := 0
	local cAlias := GetNextAlias()

	BeginSql Alias cAlias

	SELECT                                                                                                                                                               
		SUM(RD_VALOR) AS VALOR
	FROM 
		%table:SRD% SRD
	WHERE  
		SRD.%notDel%  AND
		RD_FILIAL=%xfilial:SRD% AND
		RD_XIDFOL=%Exp:cIDFOL% AND
		RD_MAT=%Exp:cMatr% AND
		RD_PERIODO=%Exp:cCompet% AND
		RD_PD=%Exp:cVerba% 

	EndSql

	If (cAlias)->(!EOF())
		nRet := (cAlias)->VALOR
	EndIf

	(cAlias)->(dbCloseArea())

Return nRet

/*/{Protheus.doc} CJBK03Valor
//TODO Retorna valor de uma verba dos movimentos da folha
@author andre.brito
@since 11/07/2020
@version 1.0
@type function
/*/

Static Function CJBK03Valor(cIDFOL,cMatr,cCompet,cVerba)

	local nRet   := 0
	local cAlias := GetNextAlias()

	BeginSql Alias cAlias

	SELECT                                                                                                                                                               
		SUM(RD_VALOR) AS VALOR
	FROM 
		%table:SRD% SRD
	WHERE  
		SRD.%notDel%  AND
		RD_FILIAL=%xfilial:SRD% AND
		RD_XIDFOL=%Exp:cIDFOL% AND
		RD_MAT=%Exp:cMatr% AND
		RD_PERIODO=%Exp:cCompet% AND
		RD_PD=%Exp:cVerba% 

	EndSql

	If (cAlias)->(!EOF())
		nRet := (cAlias)->VALOR
	EndIf

	(cAlias)->(dbCloseArea())

Return(TRANSFORM(nRet, "@E 999,999.99"))


/*/{Protheus.doc} User Function TITPENSAO
Verifica se o Codigo do Titulo na RC1 (RC1_CODTIT), corresponde a um título de PENSAO.
@type  Function
@author Luiz Enrique
@since 08/09/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function TITPENSAO()

	Local lRet:= .f.
	Local cXCodTit	:= TRIM(SuperGetMv("CI_TITPEN" ,.F.,"400"))  //Listas dos Códigos possiveis para indicar Titulo de Pensão
	Local aCodTitulo:= StrTokArr(cXCodTit, ";" ) 
	Local nCont		:= 0

	if Len(aCodTitulo) > 0
		for nCont=1 to len(aCodTitulo)			
			cXCodTit:= AVKEY(aCodTitulo[nCont],"RC1_CODTIT")
			If RC1->RC1_CODTIT == cXCodTit
				lRet:= .T.
				Exit
			Endif			
		next
	Endif
	
Return lRet

/*/{Protheus.doc} CFILTSRA
Realiza o filtro na geração do titulo ou cnab para SRA com contas não validadas
@author Carlos Henrique
@since 09/10/2020
@version undefined
@type function
/*/
User Function CFILTSRA(lCnab)
Local lRet:= .T.

if lCnab
	lRet:= (SRA2->RA_XATIVO == 'N' .OR. SRA2->RA_XSTATOC$"1,3")
else
	lRet:= !(SRA->RA_XATIVO == 'N' .OR. SRA->RA_XSTATOC$"1,3")
endif

Return lRet
