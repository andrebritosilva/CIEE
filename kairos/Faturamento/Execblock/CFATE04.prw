#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} CFATE04
Rotina de atualiza��o da ZC5 e retorno de integra��o para  Kairos e DW3 no retorno da prefeitura
@author carlos.henrique
@since 03/01/2018
@version undefined
@type function
/*/
user function CFATE04()
Local aArea		:= GETAREA()
Local lMntNFE	:= ISINCALLSTACK("U_SPDNFDANF")		// Monitoramento NFE
Local lMntNFSE	:= ISINCALLSTACK("U_F022ATUNF")		// Monitoramento NFSE
Local lTxtNFSE	:= ISINCALLSTACK("U_MTIMPNFE") .OR.;// Retorno via arquivo TXT ==> Mata915
					ISINCALLSTACK("U_C05A01GR")		// Ou manual pela rotina de monitoramento de notas(Apenas Barueri)
Local lExcNota	:= ISINCALLSTACK("U_MS520DEL")		// Tratamento para exclus�o de nota
Local lJobRet	:= ISINCALLSTACK("U_CCA07RET") 		// Job de retorno de notas pendentes
Local cMsgRet	:= ""
Local cNumNota	:= ""
Local cIdFatu	:= ""
Local cTipoRet	:= "" //Tipo de retorno ESB (x=Transmiss�o realizada;Y=Inconsist�ncia na transmiss�o;Nota Cancelada)
	
IF lMntNFSE

	cNumNota:= PARAMIXB[2]
	
	IF (Type("oXml")<>"U")
		//Tratamento para atualiza��o da ZC5 no monitoramento de cancelamento
		IF "CANCELAMENTO"$UPPER(oXml:cRECOMENDACAO)
			
			//Rotina de atualiza��o da tabela ZC5 no cancelamento		
			U_C05E04UPC(xFilial("SF3"),PARAMIXB[1],PARAMIXB[2],oXml:cRECOMENDACAO)	
			
			RESTAREA(aArea)	
			RETURN		
		ENDIF
	ENDIF	
	
	IF SF2->(EOF()) .OR. (PARAMIXB[1]+PARAMIXB[2] != SF2->F2_SERIE+SF2->F2_DOC)
		SF2->(dbSetOrder(1))
		If !SF2->(MsSeek(xFilial("SF2")+PARAMIXB[1]+PARAMIXB[2]))
			C05E04GLOG(cNumNota,"Tabela SF2 n�o posicionada serie: " +PARAMIXB[1]+" Nota: "+PARAMIXB[2])
			RESTAREA(aArea)	
			RETURN			
		ENDIF
	ENDIF
	
	IF SF3->(EOF()) .OR. (SF3->(F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA)!=xFilial("SF3")+SF2->F2_SERIE+SF2->F2_DOC+SF2->F2_CLIENTE+SF2->F2_LOJA)
		SF3->(dbSetOrder(5)) //F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+F3_IDENTFT
		If !SF3->(DbSeek(xFilial("SF3")+SF2->F2_SERIE+SF2->F2_DOC+SF2->F2_CLIENTE+SF2->F2_LOJA))
			C05E04GLOG(cNumNota,"Tabela SF3 n�o posicionada serie: " +PARAMIXB[1]+" Nota: "+PARAMIXB[2])
			RESTAREA(aArea)	
			RETURN		
		Endif
	ENDIF
	
	//N�o executar retorno para notas canceladas
	IF !EMPTY(SF3->F3_DTCANC)		
		C05E04GLOG(cNumNota,"Nota cancelada.")
		RESTAREA(aArea)	
		RETURN
	ENDIF	

	IF IsInCallStack("U_CCA07FAT") .AND. SF3->F3_FILIAL=="0007" 
		IF CVALTOCHAR(VAL(SF3->F3_NFISCAL)) == TRIM(SF3->F3_NFELETR)
			C05E04GLOG(cNumNota,"F3_NFISCAL:"+SF3->F3_NFISCAL+" igual F3_NFELETR:"+SF3->F3_NFELETR)
			RESTAREA(aArea)	
			RETURN
		ENDIF	
	ENDIF	
	
	SD2->(dbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	IF !SD2->(dbSeek(xFilial("SD2")+SF3->F3_NFISCAL+SF3->F3_SERIE+SF3->F3_CLIEFOR+SF3->F3_LOJA))
		C05E04GLOG(cNumNota,"Tabela SD2 n�o posicionada chave: "+xFilial("SD2")+SF3->F3_NFISCAL+SF3->F3_SERIE+SF3->F3_CLIEFOR+SF3->F3_LOJA)
		RESTAREA(aArea)	
		RETURN	
	ENDIF
	
	SC5->(dbSetOrder(1))
	IF !SC5->(DBSEEK(xFilial("SC5")+SD2->D2_PEDIDO) )
		C05E04GLOG(cNumNota,"Tabela SC5 n�o posicionada chave: "+xFilial("SC5")+SD2->D2_PEDIDO)
		RESTAREA(aArea)	
		RETURN	
	ENDIF	
	
	
	cIdFatu:=  SC5->C5_XIDFATU
	
		
ELSEIF lMntNFE  //Tratamento para gerar as informa��es necess�rias no monitoramento NFE

	cNumNota:= PARAMIXB[1]

	//N�o executar retorno das NFE para filiais diferente de Brasilia 
	IF CFILANT!="0006"
		RESTAREA(aArea)	
		RETURN
	ENDIF
	
	IF SF2->(EOF()) .OR. (PARAMIXB[1]+PARAMIXB[2] != SF2->F2_SERIE+SF2->F2_DOC)
		SF2->(dbSetOrder(1))
		If !SF2->(MsSeek(xFilial("SF2")+PARAMIXB[1]+PARAMIXB[2]))
			C05E04GLOG(cNumNota,"Tabela SF2 n�o posicionada serie: " +PARAMIXB[1]+" Nota: "+PARAMIXB[2])
			RESTAREA(aArea)	
			RETURN			
		ENDIF
	ENDIF	
	
	IF SF3->(EOF()) .OR. (SF3->(F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA)!=xFilial("SF3")+SF2->F2_SERIE+SF2->F2_DOC+SF2->F2_CLIENTE+SF2->F2_LOJA)
		SF3->(dbSetOrder(5)) //F3_FILIAL+F3_SERIE+F3_NFISCAL+F3_CLIEFOR+F3_LOJA+F3_IDENTFT
		If !SF3->(DbSeek(xFilial("SF3")+SF2->F2_SERIE+SF2->F2_DOC+SF2->F2_CLIENTE+SF2->F2_LOJA))
			C05E04GLOG(cNumNota,"Tabela SF3 n�o posicionada serie: " +PARAMIXB[1]+" Nota: "+PARAMIXB[2])
			RESTAREA(aArea)	
			RETURN		
		Endif
	ENDIF
	
	//N�o executar retorno para notas canceladas
	IF !EMPTY(SF3->F3_DTCANC)		
		C05E04GLOG(cNumNota,"Nota cancelada.")
		RESTAREA(aArea)	
		RETURN
	ENDIF		
	
	SD2->(dbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	IF !SD2->(dbSeek(xFilial("SD2")+SF3->F3_NFISCAL+SF3->F3_SERIE+SF3->F3_CLIEFOR+SF3->F3_LOJA))
		C05E04GLOG(cNumNota,"Tabela SD2 n�o posicionada chave: "+xFilial("SD2")+SF3->F3_NFISCAL+SF3->F3_SERIE+SF3->F3_CLIEFOR+SF3->F3_LOJA)
		RESTAREA(aArea)	
		RETURN	
	ENDIF
	
	SC5->(dbSetOrder(1))
	IF !SC5->(DBSEEK(xFilial("SC5")+SD2->D2_PEDIDO) )
		C05E04GLOG(cNumNota,"Tabela SC5 n�o posicionada chave: "+xFilial("SC5")+SD2->D2_PEDIDO)
		RESTAREA(aArea)	
		RETURN	
	ENDIF
	
	
	cIdFatu:=  SC5->C5_XIDFATU			
	
ELSEIF lTxtNFSE // Tratamento para retorno via TXT
	
	// Tabela SF3 e SF2 j� posicionada no fonte ===> MTIMPNFE
	cNumNota:= SF3->F3_NFISCAL
	
	//N�o executar retorno para notas canceladas
	IF !EMPTY(SF3->F3_DTCANC)		
		C05E04GLOG(cNumNota,"Nota cancelada.")
		RESTAREA(aArea)	
		RETURN
	ENDIF		
	
	SD2->(dbSetOrder(3)) //D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
	IF !SD2->(dbSeek(xFilial("SD2")+SF3->F3_NFISCAL+SF3->F3_SERIE+SF3->F3_CLIEFOR+SF3->F3_LOJA))
		C05E04GLOG(cNumNota,"Tabela SD2 n�o posicionada chave: "+xFilial("SD2")+SF3->F3_NFISCAL+SF3->F3_SERIE+SF3->F3_CLIEFOR+SF3->F3_LOJA)
		RESTAREA(aArea)	
		RETURN	
	ENDIF
	
	SC5->(dbSetOrder(1))
	IF !SC5->(DBSEEK(xFilial("SC5")+SD2->D2_PEDIDO) )
		C05E04GLOG(cNumNota,"Tabela SC5 n�o posicionada chave: "+xFilial("SC5")+SD2->D2_PEDIDO)
		RESTAREA(aArea)	
		RETURN	
	ENDIF
	
	
	cIdFatu:=  SC5->C5_XIDFATU
		
ELSEIF lExcNota	
	
	cIdFatu:=  SC5->C5_XIDFATU
	
ELSEIF lJobRet	
	
	cIdFatu:=  SC5->C5_XIDFATU
		
ENDIF

// N�o processa sem id de faturamento
IF EMPTY(cIdFatu)
	RESTAREA(aArea)
	RETURN
ENDIF

C05E04GLOG(cIdFatu,"Inicio do retorno de faturamento")

IF SC5->(!EOF()) .AND. SF2->(!EOF()) .AND. SF3->(!EOF())
			
	DO CASE
		
		// Tratamento da filial de Bras�lia que utiliza NFE conjugada com servi�os -->> APENAS S�O PAULO
		CASE CEMPANT=="01" .AND. SF3->F3_FILIAL== "0006" 
	
			//If !Empty(SF3->F3_DTCANC)  	//NF cancelada	
			IF lExcNota .or. (lJobRet .and. !Empty(SF3->F3_DTCANC))
				
				cTipoRet:= "Z"
			
				cMsgRet:= 	SC5->C5_NUM +CRLF+;												// Pedido Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// RPS Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// Chave NFS-e/NFE
							DTOS(SF3->F3_DTCANC) + CRLF+;									// Dt/Hr Emissao NFS-e (Cancelamento)
							TRIM(SF3->F3_CHVNFE) + CRLF+;									// Cod autoriza��o
							"NF CANCELADA" + CRLF											// Msg do TSS
				
				C05E04GLOG(cIdFatu,"Retorno de NF cancelada")
						
		 	ELSEIF "Autorizado o uso da NF-e" $ SF3->F3_DESCRET // Sucesso na emiss�o
		 		
		 		cTipoRet:= "X"	
			
				cMsgRet:= 	SC5->C5_NUM + CRLF+;												// Pedido Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// RPS Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// Chave NFS-e/NFE
							DTOS(SF2->F2_EMINFE)+StrTran(SF2->F2_HORNFE,':','')  + CRLF+;	// Dt/Hr Emissao NFS-e (Cancelamento)
							TRIM(SF3->F3_CHVNFE) + CRLF+;									// Cod autoriza��o
							TRIM(SF3->F3_DESCRET) + CRLF								// Msg do TSS
								
				C05E04GLOG(cIdFatu,"Retorno de Sucesso na emiss�o")
				
			ELSEIF !EMPTY(SF3->F3_DESCRET) // // N�o houve emiss�o de nota por inconsist�ncia
				
				cTipoRet:= "Y"
			
				cMsgRet:= 	SC5->C5_NUM + CRLF+;												// Pedido Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// RPS Protheus
							"" + CRLF+;														// NFS-e
							"" + CRLF+;														// Dt/Hr Emissao NFS-e (Cancelamento)
							"" + CRLF+;														// Cod autoriza��o
							TRIM(SF3->F3_DESCRET) + CRLF								// Msg do TSS			
			
	
				C05E04GLOG(cIdFatu,"Retorno N�o houve emiss�o de nota por inconsist�ncia")			
				
			ELSEIF TYPE("ORETORNO") == "A" // Tratamento para falha que n�o atualiza SF3
				
				IF "SCHEMA"$UPPER(ORETORNO[1]:CRECOMENDACAO)				
					
					cTipoRet:= "Y"
					
					cMsgRet:= 	SC5->C5_NUM + CRLF+;											// Pedido Protheus
								TRIM(SF3->F3_NFISCAL) + CRLF+;								// RPS Protheus
								"" + CRLF+;													// NFS-e
								"" + CRLF+;													// Dt/Hr Emissao NFS-e (Cancelamento)
								"" + CRLF+;													// Cod autoriza��o
								TRIM(ORETORNO[1]:CRECOMENDACAO) + CRLF					// Msg do TSS								
					
					C05E04GLOG(cIdFatu,"Retorno N�o houve emiss�o de nota por inconsist�ncia de SCHEMA")
					
				ENDIF
				
			EndIf		

		// Tratamento para retorno via arquivo TXT --> Barueri
		CASE lTxtNFSE 	//SF3->F3_FILIAL== "0003"

			//If !Empty(SF3->F3_DTCANC) .AND. !EMPTY(SF3->F3_NFELETR) .AND. !EMPTY(SF3->F3_CODMOT) //NF cancelada	
			IF lExcNota .or. (lJobRet .and. !Empty(SF3->F3_DTCANC))
				
				cTipoRet:= "Z"
							
				cMsgRet:= 	SC5->C5_NUM + CRLF+;												// Pedido Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// RPS Protheus
							TRIM(SF3->F3_NFELETR) + CRLF+;									// NFS-e
							DTOS(SF3->F3_DTCANC) + CRLF+;									// Dt/Hr Emissao NFS-e (Cancelamento)
							TRIM(SF3->F3_CODNFE) + CRLF+;									// Cod autoriza��o
							"NF CANCELADA" + CRLF											// Msg do TSS
				
				C05E04GLOG(cIdFatu,"Retorno de NF cancelada")
																
			ElseIf !Empty(SF3->F3_DTCANC) .AND.  EMPTY(SF3->F3_NFELETR) // N�o houve emiss�o de nota por inconsist�ncia			
	
				cTipoRet:= "Y"

				cMsgRet:= 	SC5->C5_NUM + CRLF+;												// Pedido Protheus
							"" + CRLF+;														// RPS Protheus
							"" + CRLF+;														// NFS-e
							"" + CRLF+;														// Dt/Hr Emissao NFS-e (Cancelamento)
							TRIM(SF3->F3_CODNFE) + CRLF+;									// Cod autoriza��o
							TRIM(SF3->F3_DESCRET) + CRLF								// Msg do TSS								
				
				C05E04GLOG(cIdFatu,"Retorno N�o houve emiss�o de nota por inconsist�ncia")
				
		 	ELSEIF !EMPTY(SF3->F3_NFELETR) .AND. !EMPTY(SF3->F3_CODNFE) // Sucesso na emiss�o
		 		
		 		cTipoRet:= "X"	
			
				cMsgRet:= 	SC5->C5_NUM + CRLF+;												// Pedido Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// RPS Protheus
							TRIM(SF3->F3_NFELETR) + CRLF+;									// NFS-e
							DTOS(SF2->F2_EMINFE)+StrTran(SF2->F2_HORNFE,':','')  + CRLF+;	// Dt/Hr Emissao NFS-e (Cancelamento)
							TRIM(SF3->F3_CODNFE) + CRLF+;									// Cod autoriza��o
							TRIM(SF3->F3_DESCRET) + CRLF								// Msg do TSS
				
				C05E04GLOG(cIdFatu,"Retorno de Sucesso na emiss�o")				
					
			EndIf
	
		OTHERWISE 
			
			//Tratamento para todos os processo de RPS diferente de Brasilia e Barueri						
			IF lExcNota .or. (lJobRet .and. !Empty(SF3->F3_DTCANC))
				
				cTipoRet:= "Z"
			
				cMsgRet:= 	SC5->C5_NUM + CRLF+;												// Pedido Protheus
							TRIM(SF3->F3_NFISCAL) + CRLF+;									// RPS Protheus
							TRIM(SF3->F3_NFELETR) + CRLF+;									// NFS-e
							DTOS(SF3->F3_DTCANC) + CRLF+;									// Dt/Hr Emissao NFS-e (Cancelamento)
							TRIM(SF3->F3_CODNFE) + CRLF+;									// Cod autoriza��o
							"NF CANCELADA" + CRLF											// Msg do TSS
				
				C05E04GLOG(cIdFatu,"Retorno de NF cancelada")
				
			ElseIf !Empty(SF3->F3_DTCANC) .AND.  EMPTY(SF3->F3_NFELETR) // N�o houve emiss�o de nota por inconsist�ncia			
				
				cTipoRet:= "Z"
			
				cMsgRet:= 	SC5->C5_NUM + CRLF+;												// Pedido Protheus
							"" + CRLF+;														// RPS Protheus
							"" + CRLF+;														// NFS-e
							"" + CRLF+;														// Dt/Hr Emissao NFS-e (Cancelamento)
							TRIM(SF3->F3_CODNFE) + CRLF+;									// Cod autoriza��o
							"NF CANCELADA" + CRLF											// Msg do TSS 
				
				C05E04GLOG(cIdFatu,"Retorno de NF cancelada")
				
		 	ELSEIF TRIM(SF3->F3_CODRET)=="111"  .OR. "EMISSAO DE NOTA AUTORIZADA"$UPPER(SF3->F3_DESCRET)
		 		
		 		IF !EMPTY(SF3->F3_CODNFE) // Sucesso na emiss�o
		 		
			 		cTipoRet:= "X"	
				
					cMsgRet:= 	SC5->C5_NUM + CRLF+;											// Pedido Protheus
								TRIM(SF3->F3_NFISCAL) + CRLF+;								// RPS Protheus
								TRIM(SF3->F3_NFELETR) + CRLF+;								// NFS-e
								DTOS(SF2->F2_EMINFE)+StrTran(SF2->F2_HORNFE,':','') + CRLF+;	// Dt/Hr Emissao NFS-e (Cancelamento)
								TRIM(SF3->F3_CODNFE) + CRLF+;								// Cod autoriza��o
								TRIM(SF3->F3_DESCRET) + CRLF							// Msg do TSS
					
					C05E04GLOG(cIdFatu,"Retorno de Sucesso na emiss�o")
				ENDIF
			ELSEIF (Type("oXml")<>"U") .AND. (Type("oXml:OWSERRO:OWSERROSLOTE")<>"U") // Falha na transmiss�o para o TSS

				cTipoRet:= "Y"
				
				// Tratamento para os casos que n�o possui a lista de erro do lote
				IF !EMPTY(oXml:OWSERRO:OWSERROSLOTE)
					cMsgRet:= 	SC5->C5_NUM + CRLF+;											// Pedido Protheus
								TRIM(SF3->F3_NFISCAL) + CRLF+;								// RPS Protheus
								"" + CRLF+;													// NFS-e
								"" + CRLF+;													// Dt/Hr Emissao NFS-e (Cancelamento)
								"" + CRLF+;													// Cod autoriza��o
								OXML:OWSERRO:OWSERROSLOTE[1]:CMENSAGEM +CRLF				// Msg do TSS 				
				ELSE
					//N�o gerar retorno de aguardando TSS
					IF !("AGUARDANDO"$UPPER(oXml:cRECOMENDACAO))
						cMsgRet:= SC5->C5_NUM + CRLF+;													// Pedido Protheus
									TRIM(SF3->F3_NFISCAL) + CRLF+;										// RPS Protheus
									"" + CRLF+;															// NFS-e
									"" + CRLF+;															// Dt/Hr Emissao NFS-e (Cancelamento)
									"" + CRLF+;															// Cod autoriza��o
									UPPER(oXml:cRECOMENDACAO) + " - Consultar o monitor do TSS" +CRLF	// Msg do TSS 				
					ENDIF
				ENDIF
				
				C05E04GLOG(cIdFatu,"Retorno Falha na transmiss�o para o TSS")			
				
			EndIf					
	
	ENDCASE	
	
	// Verifica se envia mensagem
	IF !EMPTY(cMsgRet)
		
		//Atualiza tabela ZC5
		U_C05E04ATU(cIdFatu,cTipoRet,cMsgRet,(lMntNFSE .or. lMntNFE .or. lTxtNFSE))
		
		//Mantido at� migra��o para tabela ZC5		
		RECLOCK("SF3",.F.)
			SF3->F3_XFLGRET:= cTipoRet	
		MSUNLOCK()		
	ELSE
		C05E04GLOG(cIdFatu,"N�o gerou mensagem de retorno")
	ENDIF

ELSE
	C05E04GLOG(cNumNota,"Tabela SC5,SF2 e SF3 n�o posicionada")
ENDIF

C05E04GLOG(cNumNota,"Fim do retorno de faturamento")
	
RESTAREA(aArea)	
RETURN
/*/{Protheus.doc} C05E04GLOG
Gera log do monitoramento de notas
@author carlos.henrique
@since 12/01/2018
@version undefined
@type function
/*/
static function C05E04GLOG(cNumNota,cMsgLog)
Local lAtivaLog	:= GetMV("CI_LOGRSOE",.T.,.F.) //Ativa log de retorno
Local cArqLog	:= "\RPS\LOG\"+CFILANT+"_"+cNumNota+".log"
Local cLogComp	:= ""

IF lAtivaLog
	IF FILE(cArqLog)
		cLogComp:= MemoRead(cArqLog)+CRLF
		FERASE(cArqLog)
				
		//N�o deixa crescer o log
		IF LEN(cLogComp) > 5000
			cLogComp:= ""
		ENDIF
		
		cLogComp+="["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"]["+CEMPANT+"-"+CFILANT+"][CFATE04]"+cMsgLog
		MEMOWRITE(cArqLog,cLogComp)
	ELSE
		cLogComp+="["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"]["+CEMPANT+"-"+CFILANT+"][CFATE04]"+cMsgLog
		MEMOWRITE(cArqLog,cLogComp)
	ENDIF
ENDIF

RETURN
/*/{Protheus.doc} C05E04ATU
Rotina de atualiza��o da tabela ZC5
@author carlos.henrique
@since 19/02/2018
@version undefined
@param cIdFatu, characters, descricao
@type function
/*/
USER FUNCTION C05E04ATU(cIdFatu,cTipoRet,cMsgRet,lRetNF)
Local aArea  := U_GETALLAREA()
Local lRet	 := .T.
Default lRetNF:= .F.

CONOUT("[C05E04ATU] cIdFatu:"+cIdFatu)

//Verifica posicionamento da tabela  --> apenas garantia
IF ZC5->(EOF()) .OR. ZC5->ZC5_IDFATU != cIdFatu
	DBSELECTAREA("ZC5")
	ZC5->(DbOrderNickName("IDFATURAME"))
	IF !ZC5->(DBSEEK(cIdFatu))
		lRet:= .F.
	ENDIF
ENDIF

IF lRet
	
	//Registra processamento na tabela de monitoramento
	RECLOCK("ZC5",.F.)
		
		ZC5->ZC5_DATA	:= SF3->F3_EMISSAO
		ZC5->ZC5_DTCANC := SF3->F3_DTCANC
		ZC5->ZC5_CODNFE	:= SF3->F3_CODNFE  
		ZC5->ZC5_NFELET	:= SF3->F3_NFELETR 
		ZC5->ZC5_CHVNFE	:= SF2->F2_CHVNFE  
		ZC5->ZC5_DESRET	:= SF3->F3_DESCRET
		ZC5->ZC5_HORFIM := SF3->F3_HORNFE 
		ZC5->ZC5_HORRET	:= TIME()
		
		IF !EMPTY(ZC5->ZC5_DTCANC)
			
			ZC5->ZC5_STATUS := "8"
			
			IF EMPTY(ZC5->ZC5_DESMOT)
				ZC5->ZC5_DESMOT:= SF3->F3_XDESMOT
			ENDIF
			
		ELSEIF cTipoRet == "X"
			ZC5->ZC5_MSGLOG	:= "Faturamento realizado com sucesso."
			ZC5->ZC5_STATUS := "4"
		ELSEIF cTipoRet == "Y"  
			//Para campinas o processamento deve ficar travado em caso de FALHA
			IF ZC5->ZC5_FILIAL=="0007" 
				ZC5->ZC5_STATUS := "T"
			ELSE
				ZC5->ZC5_STATUS := "3"
			ENDIF	  
		ELSEIF EMPTY(cTipoRet)
			ZC5->ZC5_STATUS := "2"
		ENDIF	
		
		ZC5->ZC5_LOGCOM:= cMsgRet
									
	ZC5->(MSUNLOCK())	
	
	//Cancelamento
	IF ZC5->ZC5_STATUS == "8"

		//Gera fila DW3
		U_CICOBDW3("","11") 				

		//Gera fila KAIROS
		U_CIKAIROS("","C",)

	ElseIf lRetNF

		U_CICOBDW3("","", lRetNF)

	ENDIF
	
ENDIF

U_GETALLAREA(aArea)
RETURN lRet

/*/{Protheus.doc} C05E04UPC
Rotina de atualiza��o da tabela ZC5 no cancelamento
@author carlos.henrique
@since 19/02/2018
@version undefined
@type function
/*/
User FUNCTION C05E04UPC(cFilZc5,cSerZC5,cNotaZC5,cDescRet)
Local cQryUpd:= ""

cQryUpd:= "UPDATE "+RETSQLNAME("ZC5")+" SET ZC5_DESRET='"+cDescRet+"'" 
cQryUpd+= " WHERE ZC5_FILIAL='"+cFilZc5+"' 
cQryUpd+= " AND ZC5_SERIE='"+cSerZC5+"'
cQryUpd+= " AND ZC5_NOTA='"+cNotaZC5+"'
cQryUpd+= " AND ZC5_STATUS='8'"
cQryUpd+= " AND D_E_L_E_T_=''"

//Atualiza campo do grupo de aprova��o Gestores do FLUIG na tabela ZAA
IF TCSQLEXEC(cQryUpd) < 0
	CONOUT(TCSQLERROR())				
ENDIF	

RETURN
