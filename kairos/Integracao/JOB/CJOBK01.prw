#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"
#INCLUDE "RPTDEF.CH"
#INCLUDE "FWPrintSetup.ch"   

Static cMsgLog:= ""

/*/{Protheus.doc} CJOBK01
JOB de Faturamentos de CI - CIA - RASTREAMENTO 
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
User function CJOBK01()
Local lJob		:= GetRemoteType() == -1 // Verifica se é job
Local nOpca		:= 0
local aCombo	:= {"Padrao", "Servicos diversos", "Aprendiz empregador"}
Local aParamBox := {}
Local cTZCN	 	:= ""
Private nTipPro := 0 

IF !lJob	

	aAdd(aParamBox,{3,"Informe o tipo de processamento","Padrao",aCombo,90,"",.F.})

	If ParamBox(aParamBox,"Parâmetros...")
		
		nTipPro := MV_PAR01

		IF MSGYESNO("Confirma o processamento do faturamento ?"+ CRLF + "Tipo: "+ aCombo[nTipPro] )
			nOpca:= 1
		ENDIF

	endif
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Iniciando processamento via schedule.")
	nOpca:= 1		                                                                                                          
ENDIF

IF !LockByName("CJOBK01",.T.,.T.)
	nOpca:= 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	cTZCN:= GetNextAlias()
	BeginSql Alias cTZCN
		SELECT DISTINCT ZCN_FILFAT FROM %TABLE:ZCN% ZCN 
		WHERE ZCN_FILIAL=%xfilial:ZCN%
		AND ZCN_FILFAT!=''
		AND ZCN.D_E_L_E_T_ =''		
	EndSql
	//aRet:= GETLastQuery()[2]
							
	WHILE (cTZCN)->(!EOF())	

		IF !lJob
			FWMsgRun(,{|| CJBK01PR(lJob,(cTZCN)->ZCN_FILFAT) },,"Realizando integração do faturamento para " + CEMPANT +"-"+ (cTZCN)->ZCN_FILFAT+ ", aguarde...")
		ELSE
			CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Processo Iniciado para " + CEMPANT +"-"+ (cTZCN)->ZCN_FILFAT)
			CJBK01PR(lJob,(cTZCN)->ZCN_FILFAT) 
			CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Processo Finalizado para " + CEMPANT +"-"+ (cTZCN)->ZCN_FILFAT)	
		ENDIF

	(cTZCN)->(dbSkip())
	END

	(cTZCN)->(dbCloseArea())

	//Gera CNAB de cobrança bancária
	IF !lJob
		FWMsgRun(,{|| CJBK01CB() },,"Gerando CNAB de cobrança, aguarde...")
	ELSE	
		CJBK01CB()
	ENDIF	
	
	UnLockByName("CJOBK01",.T.,.T.)	
	
ENDIF

RETURN 
/*/{Protheus.doc} CJBK01PR
Rotina de processamento
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK01PR(lJob,cFilPro)
Local cGrid	 := AllTrim(SuperGetMV("CI_GRIDFAT",,"2")) //Define se calculo será em Grid
Local cTZC5	 := GetNextAlias()
Local aRecFat:= {}
Local nX     := 0

//Realiza o fatuamento das notas

if nTipPro == 1
	BeginSql Alias cTZC5
		SELECT ZC5.R_E_C_N_O_ AS RECZC5 FROM %TABLE:ZC5% ZC5 
		INNER JOIN %TABLE:ZC1% ZC1 ON ZC5.ZC5_IDCONT = ZC1.ZC1_CODIGO AND ZC5.ZC5_LOCCON = ZC1.ZC1_LOCCTR
		WHERE ZC5_FILIAL=%Exp:cFilPro%
		AND ZC5_STATUS IN ('0','1','3')
		AND (ZC5_IDFATU!='' OR ZC5_LOTRAS!='')
		AND ZC5_DATA=%Exp:DDATABASE% 
		AND ZC5_LOTE NOT LIKE '%SD%'
		AND ZC5_LOTE NOT LIKE '%FI%'
		AND ZC5_LOTE NOT LIKE '%FF%'
		AND SUBSTRING(ZC1.ZC1_DOCLOC, 1, 8) = '61600839'
		AND ZC1.ZC1_DOCLOC != '61600839000155'
		AND ZC5.D_E_L_E_T_ =''		
	EndSql
elseif nTipPro == 2

	if cFilPro == "0001"

		BeginSql Alias cTZC5
			SELECT ZC5.R_E_C_N_O_ AS RECZC5 FROM %TABLE:ZC5% ZC5 
			INNER JOIN %TABLE:ZC1% ZC1 ON ZC5.ZC5_IDCONT = ZC1.ZC1_CODIGO AND ZC5.ZC5_LOCCON = ZC1.ZC1_LOCCTR
			WHERE ZC5_STATUS IN ('P','3')
			AND (ZC5_IDFATU!='' OR ZC5_LOTRAS!='')
			AND ZC5_LOTE LIKE '%SD%'
			AND EXISTS(
				SELECT DISTINCT M0_CODFIL FILIAL
				FROM SYS_COMPANY
				INNER JOIN %TABLE:ZCN% ZCN ON M0_CGC = ZCN_CNPJ AND ZCN.D_E_L_E_T_ = ''
				WHERE ZCN.ZCN_FILFAT IN('    ', %Exp:cFilPro%)
				AND M0_CODFIL = ZC5.ZC5_FILIAL
				AND M0_CODIGO = %Exp:cEmpAnt%
			)
			AND SUBSTRING(ZC1.ZC1_DOCLOC, 1, 8) = '61600839'
			AND ZC1.ZC1_DOCLOC != '61600839000155'
			AND ZC5.D_E_L_E_T_ =''		
		EndSql

	else

		BeginSql Alias cTZC5
			SELECT ZC5.R_E_C_N_O_ AS RECZC5 FROM %TABLE:ZC5% ZC5 
			INNER JOIN %TABLE:ZC1% ZC1 ON ZC5.ZC5_IDCONT = ZC1.ZC1_CODIGO AND ZC5.ZC5_LOCCON = ZC1.ZC1_LOCCTR
			WHERE ZC5_STATUS IN ('P','3')
			AND (ZC5_IDFATU!='' OR ZC5_LOTRAS!='') 
			AND ZC5_LOTE LIKE '%SD%'
			AND EXISTS(
				SELECT DISTINCT M0_CODFIL FILIAL
				FROM SYS_COMPANY
				INNER JOIN %TABLE:ZCN% ZCN ON M0_CGC = ZCN_CNPJ AND ZCN.D_E_L_E_T_ = ''
				WHERE ZCN.ZCN_FILFAT = %Exp:cFilPro%
				AND M0_CODFIL = ZC5.ZC5_FILIAL
				AND M0_CODIGO = %Exp:cEmpAnt%
			)
			AND SUBSTRING(ZC1.ZC1_DOCLOC, 1, 8) = '61600839'
			AND ZC1.ZC1_DOCLOC != '61600839000155'
			AND ZC5.D_E_L_E_T_ =''		
		EndSql

	endif

elseif nTipPro == 3
	BeginSql Alias cTZC5
		SELECT ZC5.R_E_C_N_O_ AS RECZC5 FROM %TABLE:ZC5% ZC5 
		INNER JOIN %TABLE:ZC1% ZC1 ON ZC5.ZC5_IDCONT = ZC1.ZC1_CODIGO AND ZC5.ZC5_LOCCON = ZC1.ZC1_LOCCTR
		WHERE ZC5_FILIAL=%Exp:cFilPro%
		AND ZC5_STATUS IN ('0')
		AND (ZC5_IDFATU!='' OR ZC5_LOTRAS!='')
		AND ZC5_DATA=%Exp:DDATABASE% 
		AND (ZC5_LOTE LIKE '%FI%' OR ZC5_LOTE LIKE '%FF%')
		AND SUBSTRING(ZC1.ZC1_DOCLOC, 1, 8) = '61600839'
		AND ZC1.ZC1_DOCLOC != '61600839000155'
		AND ZC5.D_E_L_E_T_ =''		
	EndSql
endif

//aRet:= GETLastQuery()[2]
                       	
WHILE (cTZC5)->(!EOF())		
	AADD(aRecFat,(cTZC5)->RECZC5)
(cTZC5)->(dbSkip())
END

(cTZC5)->(dbCloseArea())


IF !EMPTY(aRecFat)
    
    //Processamento em grid
    IF cGrid == "1" 
        
        oGrid := GridClient():New()
        
        lRet := oGrid:BatchExec("U_CJBK01AMB",{cEmpAnt,cFilPro,""},"U_CJBK01FAT",aRecFat)

        If !lRet .and. Empty(oGrid:aGridThreads)
			CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Nenhum Agente do GRID disponivel no Momento.")
        EndIf

        If !empty(oGrid:aErrorProc)               
            varinfo('Lista de Erro',oGrid:aErrorProc)   
        Endif   

        If !empty(oGrid:aSendProc)                 
            varinfo('Não processado',oGrid:aSendProc)   
        Endif 
	else
		For nX:= 1 to len(aRecFat)
			STARTJOB("U_CJBK01AMB" ,GetEnvServer(),.T.,{cEmpAnt,cFilPro,"U_CJBK01FAT("+CVALTOCHAR(aRecFat[nX])+")", nTipPro, cFilPro})
		Next	
	endif		
else
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Nenhum pedido pendente de faturamento")
endif

RETURN
/*/{Protheus.doc} CJBK01AMB
Prepara ambiente GRID
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
USER Function CJBK01AMB(aParms)
Local cEmpParm:= aParms[1]	// Empresa --> cEmpAnt
Local cFilParm:= aParms[2]	// Filial  --> cFilAnt
Local cFunExec:= aParms[3]	// Rotina  ---> Apenas startjob
private nTipPro := aParms[4]
private cFilPro := aParms[5]

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Preparando ambiente")
RpcSetType(3)
RPCSetEnv(cEmpParm,cFilParm)

IF !EMPTY(cFunExec)
	
	&(cFunExec)

ENDIF

Return .T.
/*/{Protheus.doc} CJBK01FAT
Rotina de faturamento
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CJBK01FAT(nRecno)
Local aCliFat:= {}
Local aLogCli:= {}

ZC5->(dbGoto(nRecno))	
IF ZC5->(!EOF())

	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Inicio faturamento:" + ZC5->ZC5_IDFATU)

	//Valida total do lote e banco de faturamento
	IF CJBK01OK()	

		BEGIN TRANSACTION	

			//Posiciona configuração de cobrança
			DbSelectArea("ZC4")
			ZC3->(dbSetOrder(1))
			ZC3->(dbSeek(xFilial("ZC3")+ZC5->ZC5_CONCOB+ZC5->ZC5_IDCONT+ZC5->ZC5_CONFAT))	

			//Posiciona configuração de faturamento
			DbSelectArea("ZC4")
			ZC4->(dbSetOrder(1))
			ZC4->(dbSeek(xFilial("ZC4")+ZC5->ZC5_CONFAT+ZC5->ZC5_IDCONT))
		
			IF EMPTY(ZC5->ZC5_CLIENT)
				//Integração de clientes
				IF !(U_CJBKCLI(@aCliFat, ZC5->ZC5_IDCONT, ZC5->ZC5_LOCCON, @aLogCli))
					RECLOCK("ZC5",.F.)
					ZC5->ZC5_STATUS	:= aLogCli[1]
					ZC5->ZC5_MSGLOG	:= aLogCli[2]
					ZC5->ZC5_LOGCOM := aLogCli[3]
					ZC5->(MSUNLOCK())					
				ENDIF	
			ELSE
				dbSelectArea("SA1")
				SA1->(Dbsetorder(1))
				IF SA1->(DBSEEK(xFilial("SA1")+ZC5->ZC5_CLIENT+ZC5->ZC5_LOJA))
					AADD(aCliFat,SA1->A1_COD)
					AADD(aCliFat,SA1->A1_LOJA)	
					AADD(aCliFat,SA1->A1_EST)	
					AADD(aCliFat,SA1->A1_COD_MUN)					
				ELSE
					RECLOCK("ZC5",.F.)
					ZC5->ZC5_STATUS	:= "3"
					ZC5->ZC5_MSGLOG	:= "Cliente não localizado na base de dados"
					ZC5->ZC5_LOGCOM := "Código: "+ ZC5->ZC5_CLIENT + CRLF + "Loja: " + ZC5->ZC5_LOJA
					ZC5->(MSUNLOCK())					
				ENDIF	
			ENDIF

			IF !EMPTY(aCliFat)
				IF !EMPTY(aCliFat[1])
					//Gera pedido e nota fiscal
					CJBK01NF(aCliFat)	
				ENDIF			
			ENDIF


		END TRANSACTION

	ENDIF	

	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Fim faturamento:" + ZC5->ZC5_IDFATU)

ENDIF

Return
/*/{Protheus.doc} CJBK01OK
Valida lote e banco de faturamento
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK01OK()
Local cTLot:= GetNextAlias()
Local lRet := .F.

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Iniciando validação.")

if nTipPro == 2

	if cFilPro == "0001"
		BeginSql Alias cTLot
			%NOPARSER%
			SELECT CAST(ZC6_SEQLOT AS int) AS ZC6_SEQLOT
				,(SELECT COUNT(*) FROM %TABLE:ZC6% ZC6B 
					WHERE EXISTS(
							SELECT DISTINCT M0_CODFIL FILIAL
							FROM SYS_COMPANY
							INNER JOIN %TABLE:ZCN% ZCN ON M0_CGC = ZCN_CNPJ AND ZCN.D_E_L_E_T_ = ''
							WHERE ZCN.ZCN_FILFAT IN('    ', %Exp:cFilPro%)
							AND M0_CODFIL = ZC6A.ZC6_FILIAL
							AND M0_CODIGO = %Exp:cEmpAnt%
						)
					AND ZC6B.ZC6_IDFATU=ZC6A.ZC6_IDFATU
					AND ZC6B.D_E_L_E_T_ ='') AS TOTAL
				,(SELECT SUM(ZC6_VALOR) FROM %TABLE:ZC6% ZC6C 
					WHERE ZC6C.ZC6_FILIAL = ZC6A.ZC6_FILIAL
					AND ZC6C.ZC6_IDFATU=ZC6A.ZC6_IDFATU
					AND ZC6C.D_E_L_E_T_ ='') AS VALOR			
			FROM %TABLE:ZC6% ZC6A 
			WHERE EXISTS(
						SELECT DISTINCT M0_CODFIL FILIAL
						FROM SYS_COMPANY
						INNER JOIN %TABLE:ZCN% ZCN ON M0_CGC = ZCN_CNPJ AND ZCN.D_E_L_E_T_ = ''
						WHERE ZCN.ZCN_FILFAT IN('    ', %Exp:cFilPro%)
						AND M0_CODFIL = ZC6A.ZC6_FILIAL
						AND M0_CODIGO = %Exp:cEmpAnt%
					)
				AND SUBSTRING(ZC6A.ZC6_LOTE, 2, 1) = 'F' 
				AND ZC6A.ZC6_IDFATU=%Exp:ZC5->ZC5_IDFATU%
				AND ZC6A.D_E_L_E_T_ = ''
		EndSql	
	else
		BeginSql Alias cTLot
			%NOPARSER%
			SELECT CAST(ZC6_SEQLOT AS int) AS ZC6_SEQLOT
				,(SELECT COUNT(*) FROM %TABLE:ZC6% ZC6B 
					WHERE EXISTS(
							SELECT DISTINCT M0_CODFIL FILIAL
							FROM SYS_COMPANY
							INNER JOIN %TABLE:ZCN% ZCN ON M0_CGC = ZCN_CNPJ AND ZCN.D_E_L_E_T_ = ''
							WHERE ZCN.ZCN_FILFAT = %Exp:cFilPro%
							AND M0_CODFIL = ZC6A.ZC6_FILIAL
							AND M0_CODIGO = %Exp:cEmpAnt%
						)
					AND ZC6B.ZC6_IDFATU=ZC6A.ZC6_IDFATU
					AND ZC6B.D_E_L_E_T_ ='') AS TOTAL
				,(SELECT SUM(ZC6_VALOR) FROM %TABLE:ZC6% ZC6C 
					WHERE ZC6C.ZC6_FILIAL = ZC6A.ZC6_FILIAL
					AND ZC6C.ZC6_IDFATU=ZC6A.ZC6_IDFATU
					AND ZC6C.D_E_L_E_T_ ='') AS VALOR			
			FROM %TABLE:ZC6% ZC6A 
			WHERE EXISTS(
						SELECT DISTINCT M0_CODFIL FILIAL
						FROM SYS_COMPANY
						INNER JOIN %TABLE:ZCN% ZCN ON M0_CGC = ZCN_CNPJ AND ZCN.D_E_L_E_T_ = ''
						WHERE ZCN.ZCN_FILFAT = %Exp:cFilPro%
						AND M0_CODFIL = ZC6A.ZC6_FILIAL
						AND M0_CODIGO = %Exp:cEmpAnt%
					)
				AND SUBSTRING(ZC6A.ZC6_LOTE, 2, 1) = 'F' 
				AND ZC6A.ZC6_IDFATU=%Exp:ZC5->ZC5_IDFATU%
				AND ZC6A.D_E_L_E_T_ = ''
		EndSql
	endif
else
	BeginSql Alias cTLot
		%NOPARSER%
		SELECT CAST(ZC6_SEQLOT AS int) AS ZC6_SEQLOT
			,(SELECT COUNT(*) FROM %TABLE:ZC6% ZC6B 
				WHERE ZC6B.ZC6_FILIAL = ZC6A.ZC6_FILIAL
				AND ZC6B.ZC6_IDFATU=ZC6A.ZC6_IDFATU
				AND ZC6B.D_E_L_E_T_ ='') AS TOTAL
			,(SELECT SUM(ZC6_VALOR) FROM %TABLE:ZC6% ZC6C 
				WHERE ZC6C.ZC6_FILIAL = ZC6A.ZC6_FILIAL
				AND ZC6C.ZC6_IDFATU=ZC6A.ZC6_IDFATU
				AND ZC6C.D_E_L_E_T_ ='') AS VALOR			
		FROM %TABLE:ZC6% ZC6A 
		WHERE ZC6A.ZC6_FILIAL = %xfilial:ZC6% 
			AND SUBSTRING(ZC6A.ZC6_LOTE, 2, 1) = 'F' 
			AND ZC6A.ZC6_IDFATU=%Exp:ZC5->ZC5_IDFATU%
			AND ZC6A.D_E_L_E_T_ = ''
	EndSql	 
endif

//aRet:= GETLastQuery()[2]
IF (cTLot)->(!EOF())
	WHILE (cTLot)->(!EOF())	
		
		IF (cTLot)->ZC6_SEQLOT == (cTLot)->TOTAL
			cBcoFat:= CJBK01BF(ZC5->ZC5_BCOFAT,(cTLot)->VALOR,ZC5->ZC5_CONFAT,ZC5->ZC5_IDCONT)
			
			IF EMPTY(cBcoFat) .AND. (cTLot)->VALOR == 0
				RECLOCK("ZC5",.F.)
				ZC5->ZC5_STATUS	:= "3"
				ZC5->ZC5_MSGLOG	:= "Banco de faturamento não tá preenchido ou valor tá zerado."
				ZC5->(MSUNLOCK())				
			ELSE
				
				RECLOCK("ZC5",.F.)
				ZC5->ZC5_BCOFAT:= cBcoFat
				ZC5->ZC5_VALOR := (cTLot)->VALOR
				ZC5->(MSUNLOCK())
				
				lRet:= .T.

			ENDIF

		ELSE
			RECLOCK("ZC5",.F.)
			ZC5->ZC5_MSGLOG	:= "Quantidade total do lote divergente"
			ZC5->ZC5_LOGCOM	:= ""
			ZC5->(MSUNLOCK())	
		ENDIF

	(cTLot)->(dbSkip())
	END
ELSE
	RECLOCK("ZC5",.F.)
	ZC5->ZC5_STATUS	:= "3"
	ZC5->ZC5_MSGLOG	:= "Não foi possível identificar o final do lote do faturamento."
	ZC5->(MSUNLOCK())	
ENDIF

(cTLot)->(dbCloseArea())

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Fim validação.")

return lRet
/*/{Protheus.doc} CJBK01NF
Rotina de geração de clientes de acordo com contrato e local de contrato
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK01NF(aCliFat)
Local aCab	 := {}
Local aItens := {}
Local aLinha := {}
Local cMsgNot:= ""
Local nProd	 := 1
Local cNotaInc	:= ""
LOCAL cCpoMsgNF := ALLTRIM(GETMV("MV_CMPUSR"))
LOCAL aProd		:= STRTOKARR2(AllTrim(GetNewPar("MV_XPRDKAY"," ; ")),";",.T.)
LOCAL cTESKay	:= AllTrim(GetNewPar("MV_XTESKAY"," "))
LOCAL cCondPg	:= AllTrim(GetNewPar("MV_XCONKAY"," ")) 
Local dDtVenc   := ZC5->ZC5_DATVEN 
Local cTab		:= ""
Local nItem		:= 1
Local aRetZc0   := {}
Local cNomeUsr  := UsrRetName(__cUserID)
local cNumSeq

Private lMsHelpAuto 	:= .T.
Private lMsErroAuto 	:= .F.
Private lAutoErrNoFile	:= .T.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Iniciando Faturamento.")

//Adiciona pipe no texto para filial de barueri
IF ZC5->ZC5_FILIAL == "0003"
	cMsgNot:= CJBK01PP(ZC5->ZC5_MSGNOT)
ELSE
	cMsgNot:= ZC5->ZC5_MSGNOT	
ENDIF	 

//Tratamento de mensagem da nota
DBSELECTAREA("SM4")
IF SM4->(FieldPos("M4_XMENESP")) > 0
	DBSELECTAREA("SF4")
	SF4->(DBSETORDER(1))
	IF SF4->(DBSEEK(XFILIAL()+cTESKay)) 
		SM4->(DBSETORDER(1))
		IF SM4->(DBSEEK(xFilial("SM4")+SF4->F4_FORMULA))
			cMsgNot+= SM4->M4_XMENESP
		ENDIF
	ENDIF									
ENDIF

IF ZC5->ZC5_FILIAL == "0013"
	IF RIGHT(TRIM(SM0->M0_CODMUN),5)!= TRIM(aCliFat[4])
		nProd:= 2
	ENDIF					
ELSE						
	IF TRIM(aCliFat[3])!= SM0->M0_ESTCOB
		nProd:= 2
	ENDIF
ENDIF

IF dDtVenc < DDATABASE
	dDtVenc:= DDATABASE
ENDIF

IF "SD"$ZC5->ZC5_LOTE
	
	cTab:= GetNextAlias()

	BeginSql Alias cTab
		SELECT * FROM %TABLE:ZC6% ZC6 
		WHERE ZC6_FILIAL=%Exp:ZC5->ZC5_FILIAL%
		AND ZC6_IDFATU=%Exp:ZC5->ZC5_IDFATU%
		AND ZC6.D_E_L_E_T_ =''		
	EndSql
	
	//aRet:= GETLastQuery()[2]
	IF (cTab)->(!EOF())

		if ZC5->ZC5_PARC2 > 0
			AADD(aCab,{"C5_PARC2"   , ZC5->ZC5_PARC2 	, Nil})
			AADD(aCab,{"C5_DATA2"   , ZC5->ZC5_DATA2  	, Nil})	
		endif
		if ZC5->ZC5_PARC3 > 0
			AADD(aCab,{"C5_PARC3"   , ZC5->ZC5_PARC3 	, Nil})
			AADD(aCab,{"C5_DATA3"   , ZC5->ZC5_DATA3  	, Nil})	
		endif
		if ZC5->ZC5_PARC4 > 0
			AADD(aCab,{"C5_PARC4"   , ZC5->ZC5_PARC4 	, Nil})
			AADD(aCab,{"C5_DATA4"   , ZC5->ZC5_DATA4  	, Nil})	
		endif
		if ZC5->ZC5_PARC5 > 0
			AADD(aCab,{"C5_PARC5"   , ZC5->ZC5_PARC5 	, Nil})
			AADD(aCab,{"C5_DATA5"   , ZC5->ZC5_DATA5  	, Nil})	
		endif
		if ZC5->ZC5_PARC6 > 0
			AADD(aCab,{"C5_PARC6"   , ZC5->ZC5_PARC6 	, Nil})
			AADD(aCab,{"C5_DATA6"   , ZC5->ZC5_DATA6  	, Nil})	
		endif
		if ZC5->ZC5_PARC7 > 0
			AADD(aCab,{"C5_PARC7"   , ZC5->ZC5_PARC7 	, Nil})
			AADD(aCab,{"C5_DATA7"   , ZC5->ZC5_DATA7  	, Nil})	
		endif
		if ZC5->ZC5_PARC8 > 0
			AADD(aCab,{"C5_PARC8"   , ZC5->ZC5_PARC8 	, Nil})
			AADD(aCab,{"C5_DATA8"   , ZC5->ZC5_DATA8  	, Nil})	
		endif
		if ZC5->ZC5_PARC9 > 0
			AADD(aCab,{"C5_PARC9"   , ZC5->ZC5_PARC9 	, Nil})
			AADD(aCab,{"C5_DATA9"   , ZC5->ZC5_DATA9  	, Nil})	
		endif
		if ZC5->ZC5_PARCA > 0
			AADD(aCab,{"C5_PARCA"   , ZC5->ZC5_PARCA 	, Nil})
			AADD(aCab,{"C5_DATAA"   , ZC5->ZC5_DATAA  	, Nil})	
		endif
		if ZC5->ZC5_PARCB > 0
			AADD(aCab,{"C5_PARCB"   , ZC5->ZC5_PARCB 	, Nil})
			AADD(aCab,{"C5_DATAB"   , ZC5->ZC5_DATAB  	, Nil})	
		endif
		if ZC5->ZC5_PARCC > 0
			AADD(aCab,{"C5_PARCC"   , ZC5->ZC5_PARCC 	, Nil})
			AADD(aCab,{"C5_DATAC"   , ZC5->ZC5_DATAC  	, Nil})	
		endif
		if ZC5->ZC5_PARCD > 0
			AADD(aCab,{"C5_PARCD"   , ZC5->ZC5_PARCD 	, Nil})
			AADD(aCab,{"C5_DATAD"   , ZC5->ZC5_DATAD  	, Nil})	
		endif
		if ZC5->ZC5_PARCE > 0
			AADD(aCab,{"C5_PARCE"   , ZC5->ZC5_PARCE 	, Nil})
			AADD(aCab,{"C5_DATAE"   , ZC5->ZC5_DATAE  	, Nil})	
		endif
		if ZC5->ZC5_PARCF > 0
			AADD(aCab,{"C5_PARCF"   , ZC5->ZC5_PARCF 	, Nil})
			AADD(aCab,{"C5_DATAF"   , ZC5->ZC5_DATAF  	, Nil})	
		endif
		if ZC5->ZC5_PARCG > 0
			AADD(aCab,{"C5_PARCG"   , ZC5->ZC5_PARCG 	, Nil})
			AADD(aCab,{"C5_DATAG"   , ZC5->ZC5_DATAG  	, Nil})	
		endif	
		if ZC5->ZC5_PARCH > 0
			AADD(aCab,{"C5_PARCH"   , ZC5->ZC5_PARCH 	, Nil})
			AADD(aCab,{"C5_DATAH"   , ZC5->ZC5_DATAH  	, Nil})																																										
		endif	
		if ZC5->ZC5_PARCI > 0
			AADD(aCab,{"C5_PARCI"   , ZC5->ZC5_PARCI 	, Nil})
			AADD(aCab,{"C5_DATAI"   , ZC5->ZC5_DATAI  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCJ > 0
			AADD(aCab,{"C5_PARCJ"   , ZC5->ZC5_PARCJ 	, Nil})
			AADD(aCab,{"C5_DATAJ"   , ZC5->ZC5_DATAJ  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCK > 0
			AADD(aCab,{"C5_PARCK"   , ZC5->ZC5_PARCK 	, Nil})
			AADD(aCab,{"C5_DATAK"   , ZC5->ZC5_DATAK  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCL > 0
			AADD(aCab,{"C5_PARCL"   , ZC5->ZC5_PARCL 	, Nil})
			AADD(aCab,{"C5_DATAL"   , ZC5->ZC5_DATAL  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCM > 0
			AADD(aCab,{"C5_PARCM"   , ZC5->ZC5_PARCM 	, Nil})
			AADD(aCab,{"C5_DATAM"   , ZC5->ZC5_DATAM  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCN > 0
			AADD(aCab,{"C5_PARCN"   , ZC5->ZC5_PARCN 	, Nil})
			AADD(aCab,{"C5_DATAN"   , ZC5->ZC5_DATAN  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCO > 0
			AADD(aCab,{"C5_PARCO"   , ZC5->ZC5_PARCO 	, Nil})
			AADD(aCab,{"C5_DATAO"   , ZC5->ZC5_DATAO  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCP > 0
			AADD(aCab,{"C5_PARCP"   , ZC5->ZC5_PARCP 	, Nil})
			AADD(aCab,{"C5_DATAP"   , ZC5->ZC5_DATAP  	, Nil})																																										
		endif
		if ZC5->ZC5_PARCQ > 0
			AADD(aCab,{"C5_PARCQ"   , ZC5->ZC5_PARCQ 	, Nil})
			AADD(aCab,{"C5_DATAQ"   , ZC5->ZC5_DATAQ  	, Nil})																																										
		endif

		AADD(aCab,{"C5_TIPO"    , "N"       		, Nil})
		AADD(aCab,{"C5_CLIENTE" , aCliFat[1] 		, Nil})
		AADD(aCab,{"C5_LOJACLI" , aCliFat[2]  		, Nil})
		AADD(aCab,{"C5_ESTPRES" , aCliFat[3]  		, Nil})
		AADD(aCab,{"C5_MUNPRES" , aCliFat[4]		, Nil})
		AADD(aCab,{"C5_EMISSAO" , ZC5->ZC5_DATA		, Nil})
		AADD(aCab,{"C5_PESOL"   , 1					, Nil})
		AADD(aCab,{"C5_PBRUTO"  , 1					, Nil})
		AADD(aCab,{"C5_INCISS"  , "N"    	   		, Nil})
		AADD(aCab,{"C5_MOEDA"   , 1        	 		, Nil})
		AADD(aCab,{"C5_CONDPAG" , cCondPg			, Nil}) 
		AADD(aCab,{"C5_PARC1"   , ZC5->ZC5_PARC1 	, Nil})
		AADD(aCab,{"C5_DATA1"   , ZC5->ZC5_DATA1  	, Nil})	

		AADD(aCab,{cCpoMsgNF 	, cMsgNot			, NIL }) 
		AADD(aCab,{"C5_XIDFATU" , ZC5->ZC5_IDFATU	, NIL }) 


		WHILE (cTab)->(!EOF())	

			AADD(aLinha,{"C6_ITEM"	 , StrZero(nItem, TAMSX3("C6_ITEM")[1]) , NIL})
			Aadd(aLinha,{"C6_PRODUTO", (cTab)->ZC6_PRODUT ,NIL} )
			//Aadd(aLinha,{"C6_PRODUTO", aProd[nProd] ,NIL} )
			Aadd(aLinha,{"C6_TES"	 , cTESKay ,NIL} )
			AADD(aLinha,{"C6_QTDVEN" , (cTab)->ZC6_QTDE , NIL})
			AADD(aLinha,{"C6_QTDLIB" , (cTab)->ZC6_QTDE , NIL})
			AADD(aLinha,{"C6_PRCVEN" , (cTab)->ZC6_VALOR , NIL})
			AADD(aLinha,{"C6_PRUNIT" , (cTab)->ZC6_VALOR , NIL})
			AADD(aLinha,{"C6_VALOR"  , (cTab)->ZC6_QTDE * (cTab)->ZC6_VALOR , NIL})
			AADD(aLinha,{"C6_ITEMCTA" , (cTab)->ZC6_ITEMD , NIL})

			AADD(aItens,aLinha)		
			
			nItem++

		(cTab)->(dbSkip())	
		END
	ENDIF
	
	(cTab)->(dbCloseArea())	

ELSE

	AADD(aCab,{"C5_TIPO"    , "N"       		, Nil})
	AADD(aCab,{"C5_CLIENTE" , aCliFat[1] 		, Nil})
	AADD(aCab,{"C5_LOJACLI" , aCliFat[2]  		, Nil})
	AADD(aCab,{"C5_ESTPRES" , aCliFat[3]  		, Nil})
	AADD(aCab,{"C5_MUNPRES" , aCliFat[4]		, Nil})
	AADD(aCab,{"C5_EMISSAO" , ZC5->ZC5_DATA		, Nil})
	AADD(aCab,{"C5_PESOL"   , 1					, Nil})
	AADD(aCab,{"C5_PBRUTO"  , 1					, Nil})
	AADD(aCab,{"C5_INCISS"  , "N"    	   		, Nil})
	AADD(aCab,{"C5_MOEDA"   , 1        	 		, Nil})
	AADD(aCab,{"C5_CONDPAG" , cCondPg			, Nil})
	AADD(aCab,{"C5_PARC1"   , ZC5->ZC5_VALOR	, Nil})
	AADD(aCab,{"C5_DATA1"   , dDtVenc 			, Nil})	
	AADD(aCab,{cCpoMsgNF 	, cMsgNot			, NIL }) 
	AADD(aCab,{"C5_XIDFATU" , ZC5->ZC5_IDFATU	, NIL }) 

	AADD(aLinha,{"C6_ITEM"	 , StrZero(nItem, TAMSX3("C6_ITEM")[1]) , NIL})
	Aadd(aLinha,{"C6_PRODUTO", aProd[nProd] ,NIL} )
	Aadd(aLinha,{"C6_TES"	 , cTESKay ,NIL} )
	AADD(aLinha,{"C6_QTDVEN" , 1 , NIL})
	AADD(aLinha,{"C6_QTDLIB" , 1 , NIL})
	AADD(aLinha,{"C6_PRCVEN" , ZC5->ZC5_VALOR , NIL})
	AADD(aLinha,{"C6_PRUNIT" , ZC5->ZC5_VALOR , NIL})
	AADD(aLinha,{"C6_VALOR"  , ZC5->ZC5_VALOR , NIL})

	AADD(aItens,aLinha)
ENDIF

MSExecAuto({|x,y,z|Mata410(x,y,z)},aCab,aItens,3)

If lMsErroAuto
	
	cMsgLog:= U_CAJERRO(GetAutoGRLog(),.T.)

	RECLOCK("ZC5",.F.)
	ZC5->ZC5_STATUS	:= "3"
	ZC5->ZC5_MSGLOG	:= "Erro na integração do pedido de venda."
	ZC5->ZC5_LOGCOM	:= cMsgLog
	ZC5->(MSUNLOCK())	
	
// Verifica-se a nota já foi gerada
ELSEIF EMPTY(SC5->C5_NOTA)	
			
	// Preparacao do array com itens a serem faturados
	SB1->(DbSetOrder(1))
	SB2->(DbSetOrder(1))
	SF4->(DbSetOrder(1))
	SC5->(DbSetOrder(1))
	SC5->(DbSeek( xFilial('SC5')+SC5->C5_NUM ))
	SE4->(DbSetOrder(1))
	SE4->(DbSeek(xFilial('SE4')+SC5->C5_CONDPAG) )
	SC6->(DbSetOrder(1) )
	SC6->(DbSeek( xFilial('SC6')+SC5->C5_NUM ) )
	
	aPvlNfs:={}
	While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) = xFilial('SC5')+SC5->C5_NUM
		If SC9->( DbSeek( xFilial('SC9')+SC5->C5_NUM + SC6->C6_ITEM ) )  //FILIAL+NUMERO+ITEM
			SB1->(DbSeek(xFilial('SB1')+SC9->C9_PRODUTO) )               //FILIAL+PRODUTO
			SB2->(DbSeek(xFilial('SB2')+SC9->(C9_PRODUTO+C9_LOCAL)) )    //FILIAL+PRODUTO+LOCAL
			SF4->(DbSeek(xFilial('SF4')+SC6->C6_TES) )                //FILIAL+CODIGO
			
			aAdd(aPvlNfs,{ SC9->C9_PEDIDO,SC9->C9_ITEM,SC9->C9_SEQUEN,SC9->C9_QTDLIB,;
			SC9->C9_PRCVEN,SC9->C9_PRODUTO,SF4->F4_ISS=='S',SC9->(RecNo()),;
			SC5->(RecNo()),SC6->(RecNo()),SE4->(RecNo()),SB1->(RecNo()),;
			SB2->(RecNo()),SF4->(RecNo()),SB2->B2_LOCAL,0,SC9->C9_QTDLIB2})
		EndIf
		SC6->( dbSkip() )
	EndDo
	
	IF !EMPTY(aPvlNfs)
		
		//Regra verificar se trata-se de faturamento de aprendiz
		IF ("FF" $ ALLTRIM(ZC5->ZC5_LOTE)) .OR. ("FI" $ ALLTRIM(ZC5->ZC5_LOTE)) 

			IF ZC3->ZC3_EMINF == "1" .AND. ZC3->ZC3_CISEPA == "1" .AND. ZC5->ZC5_TIPFAT == "1" //EmiteNF=SIM, CI Separada=SIM e Tipo Fatura=CI
				cSerNF :=PadR(TRIM(GetMv("CI_SERIE",.F.,"RPS")),Len(SF2->F2_SERIE))
			ELSE
				cSerNF :=PadR(TRIM(GetMv("CI_SERNTP",.F.,"NTP")),Len(SF2->F2_SERIE)) // Série que não transmite para prefeitura.
			ENDIF

		ELSE
		
			IF ZC3->ZC3_EMINF == "1"
				cSerNF :=PadR(TRIM(GetMv("CI_SERIE",.F.,"RPS")),Len(SF2->F2_SERIE))
			ELSE
				cSerNF :=PadR(TRIM(GetMv("CI_SERNTP",.F.,"NTP")),Len(SF2->F2_SERIE)) // Série que não transmite para prefeitura.
			ENDIF

		ENDIF

		MaNfsInit() //Inicializa as variaveis Staticas utilizadas no Programa MATA461
		//-- Inclui a nota
		cNotaInc	:= MaPvlNfs(aPvlNfs,cSerNF, .T., .T., .T., .T., .F., 0, 0, .F., .F.,,,)
		
		If Empty(cNotaInc)	
			RECLOCK("ZC5",.F.)
			ZC5->ZC5_STATUS	:= "3"
			ZC5->ZC5_MSGLOG	:= "Erro na geração da Nota."
			ZC5->(MSUNLOCK())				
		else
				
			//Ajuste de e-mail na filial de campinas
			IF CEMPANT=="01" .AND. CFILANT=="0007" .AND. !EMPTY(SA1->A1_EMAIL) .AND. ";"$SA1->A1_EMAIL			
				RECLOCK("SA1",.F.)
					SA1->A1_EMAIL:= SUBSTR(SA1->A1_EMAIL,1,AT(";",SA1->A1_EMAIL)-1)
				MSUNLOCK() 
			ENDIF			
		
			RECLOCK("ZC5",.F.)
				//ZC5->ZC5_DATA 	:= SF3->F3_EMISSAO
				ZC5->ZC5_NOTA	:= SF3->F3_NFISCAL 
				ZC5->ZC5_SERIE	:= SF3->F3_SERIE   
				ZC5->ZC5_CLIENT	:= SF3->F3_CLIEFOR 
				ZC5->ZC5_LOJA  	:= SF3->F3_LOJA
				ZC5->ZC5_NOMCLI	:= SA1->A1_NOME    
				ZC5->ZC5_ESTADO	:= SF3->F3_ESTADO
				ZC5->ZC5_MUNPRE	:= SC5->C5_MUNPRES
				ZC5->ZC5_MUNDES	:= POSICIONE("CC2",1,XFILIAL("CC2")+ZC5->(ZC5_ESTADO+ZC5_MUNPRE),"CC2_MUN")  
				ZC5->ZC5_EMAIL 	:= SA1->A1_EMAIL 
				ZC5->ZC5_HORFIM := TIME()
				ZC5->ZC5_STATUS	:= "2"	//Sucesso no processamento
				ZC5->ZC5_MSGLOG	:= "Faturamento realizado com sucesso"
				ZC5->ZC5_DTCANC	:= CTOD("")
				ZC5->ZC5_DESMOT := ""
				ZC5->ZC5_LOGCOM	:= ""				
			ZC5->(MSUNLOCK())	

			IF SF2->(!EOF()) .AND. SF2->F2_DOC == cNotaInc 			
				RECLOCK("SF2",.F.)
					SF2->F2_XIDFATU:= ZC5->ZC5_IDFATU
				MSUNLOCK()	
			ENDIF		

			if !empty(ZC5->ZC5_NUMPAR) .and. val(ZC5->ZC5_NUMPAR) > 1
				SE1->(Dbsetorder(1))

				SE1->(msSeek(xFilial("SE1") + SE1->E1_PREFIXO + SE1->E1_NUM + "A"))
			endif

			//Adiciona recno do titulo para gerar bordero
			IF SE1->(!EOF()) .AND. SE1->E1_NUM == cNotaInc 

				while SE1->(!EOF()) .AND. SE1->E1_NUM == cNotaInc 
				    
				    RECLOCK("SE1",.F.)

					IF !empty(ZC5->ZC5_NUMSOC)
						SE1->E1_XIDFLG  := alltrim(ZC5->ZC5_NUMSOC)
						SE1->E1_XCOMPET := alltrim(ZC5->ZC5_COMPET)
					endif
				    
					SE1->E1_XIDFATU:= ZC5->ZC5_IDFATU
					SE1->E1_XIDCNT := ZC5->ZC5_IDCONT
					SE1->E1_XIDLOC := ZC5->ZC5_LOCCON
					SE1->E1_XCOMPET:= ZC5->ZC5_COMPET
					SE1->E1_XAPD   := CJBKFATAPD(SE1->E1_FILORIG,ZC5->ZC5_IDFATU)
					If SE1->(ColumnPos( "E1_XNOME")) > 0
						SE1->E1_XNOME  := cNomeUsr
					EndIf
					
					aRetZc0 := RetTpCont(ZC5->ZC5_FILIAL,ZC5->ZC5_IDCONT)
					
					If !Empty(aRetZc0)
						If Alltrim (aRetZc0[1][1]) == "1" //Estagio
						
						    //TIPO 1C - ATIVIDADE ESTÁGIO
						    
							SE1->E1_XREDUZ  := "11502"
							SE1->E1_DEBITO  := "101020100002"
							SE1->E1_XREDCRE := "13001"
							SE1->E1_CREDIT  := "101020400001"
							SE1->E1_HIST    := "FATURAMENTO ESTAGIO"
							
						ElseIf  Alltrim (aRetZc0[1][1]) == "2" //Aprendiz
						
							If Alltrim (aRetZc0[1][2]) == "1" //Capacitador
							    
							   //TIPO 4C - APRENDIZ CAPACITADOR (KAIROS)
							    
								SE1->E1_XREDUZ  := "11503"
			                    SE1->E1_DEBITO  := "101020100003"
			                    SE1->E1_XREDCRE := "13002"
			                    SE1->E1_CREDIT  := "101020400002"
			                    SE1->E1_HIST    := "FATURAMENTO APRENDIZ CAPACITADOR"
			
			                ElseIf Alltrim (aRetZc0[1][2]) == "2" //2=Empregador 
			                	
			                	//TIPO 5C - CONTRIBUIÇÃO INICIAL
			                    
			                    SE1->E1_XREDUZ  := "11506"
			                    SE1->E1_DEBITO  := "101020100006"
			                    SE1->E1_XREDCRE := "13005"
			                    SE1->E1_CREDIT  := "101020400005"
			                    SE1->E1_HIST    := "FATURAMENTO APRENDIZ EMPREGADOR"
			
			                EndIf
			                
						EndIf
					EndIf
					
					MSUNLOCK()
					
					if alltrim(SE1->E1_XAPD)=="S" .and. EmiteRecibo() 

						if GeraRecAcumulado()

							nVlrAcum := SomaVlrRec()

							if nVlrAcum>0

								//Grava tabela de recibo
								cNumSeq := U_CCK12INC("", cValtoChar(year(dDataBase)) + cValtoChar(day(dDataBase)), alltrim(ZC5->ZC5_IDCONT), alltrim(ZC5->ZC5_LOCCON), stod(space(8)), nVlrAcum)

								//Gera recibo
								U_CJBK01RC(nVlrAcum, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_PORTADO, SE1->E1_AGEDEP, SE1->E1_CONTA, SE1->E1_VENCREA,cNumSeq,.f.,SE1->E1_XCOMPET, SE1->E1_XIDCNT)

							endif

						else

							//Grava tabela de recibo
							cNumSeq := U_CCK12INC("", cValtoChar(year(dDataBase)) + cValtoChar(day(dDataBase)), alltrim(ZC5->ZC5_IDCONT), alltrim(ZC5->ZC5_LOCCON), stod(space(8)), SE1->E1_VALOR)

							//Gera recibo
							U_CJBK01RC(SE1->E1_VALOR, SE1->E1_CLIENTE, SE1->E1_LOJA, SE1->E1_PORTADO, SE1->E1_AGEDEP, SE1->E1_CONTA, SE1->E1_VENCREA,cNumSeq,.f.,SE1->E1_XCOMPET, SE1->E1_XIDCNT)
						
						endif

					endif

					//Tratamento para gerar fila DW3 quando não envia para banco
					IF ZC3->ZC3_ENVBCO != "1"
						U_CICOBDW3("","0")  // Situação Carteira CIEE
					ENDIF

					MsgRun ( "Contabilizando faturamentos...", '', { || U_ProcCtb()() } )

					SE1->(dbSkip())

				enddo
					
			ENDIF
		EndIf
	ELSE
		RECLOCK("ZC5",.F.)
		ZC5->ZC5_STATUS	:= "3"
		ZC5->ZC5_MSGLOG	:= "Erro na geração da Nota."
		ZC5->(MSUNLOCK())	
	EndIf	
ENDIF

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Fim Faturamento.")

RETURN
/*/{Protheus.doc} CJBK01CB
Rotina de geração do CNAB de cobrança bancária
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK01CB()
Local cTab		:= GetNextAlias()
Local cNumBor  := ""
Local aTitFat  := {}
Local aTitBor := {}
Local cArqRem  := ""
Local nPosBco  := 0
Local nCnta
Local nCntb
Private LABORTA:= .F.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Iniciando CNAB de cobrança.")

if nTipPro == 2

	BeginSql Alias cTab
		SELECT DISTINCT ZC5_BCOFAT,SE1.R_E_C_N_O_  AS  RECSE1  FROM %TABLE:SE1% SE1 
		INNER JOIN %TABLE:ZC5% ZC5 ON ZC5_IDFATU=E1_XIDFATU
			AND ZC5_STATUS='2' 
			AND ZC5.D_E_L_E_T_ =''		
		WHERE E1_NUMBOR=''
		AND zc5.ZC5_LOTE LIKE '%SD%'
		AND SE1.D_E_L_E_T_ =''		
	EndSql

else

	BeginSql Alias cTab
		SELECT DISTINCT ZC5_BCOFAT,SE1.R_E_C_N_O_ AS RECSE1 FROM %TABLE:SE1% SE1 
		INNER JOIN %TABLE:ZC5% ZC5 ON ZC5_IDFATU=E1_XIDFATU
			AND ZC5_STATUS='2' 
			AND ZC5_DATA=%Exp:DDATABASE% 
			AND ZC5.D_E_L_E_T_ =''
		INNER JOIN %TABLE:ZC3% ZC3 ON ZC3_IDCOBR=ZC5_CONCOB  //Avalias se envia para banco na configuração de cobrança
			AND ZC3_IDCONT=ZC5_IDCONT 
			AND ZC3.D_E_L_E_T_ =''
			AND ZC3_ENVBCO = '1'			
		WHERE E1_NUMBOR=''
		AND SE1.D_E_L_E_T_ =''		
	EndSql

endif

//aRet:= GETLastQuery()[2]
								
WHILE (cTab)->(!EOF())		
	
	IF (nPosBco:= ASCAN(aTitBor,{|x| x[1]==(cTab)->ZC5_BCOFAT})) == 0
		
		IF (cTab)->ZC5_BCOFAT == "237"
			AADD(aTitBor,{"237","33910","866202","BRACOB.rem","\arq_txt\kairos\Secor\Bradesco\Remessa\",{}}) 
		ELSEIF (cTab)->ZC5_BCOFAT == "341"
			AADD(aTitBor,{"341","0350 ","740437","ITAUCOB.rem","\arq_txt\kairos\Secor\Itau\Remessa\",{}}) 
		ENDIF
		nPosBco:= LEN(aTitBor)

		AADD(aTitBor[nPosBco][6],(cTab)->RECSE1)
	ELSE
		AADD(aTitBor[nPosBco][6],(cTab)->RECSE1)	
	ENDIF

(cTab)->(dbSkip())	
END

(cTab)->(dbCloseArea())		

For nCnta:=1 to len(aTitBor)
	
	cNumBor := Soma1(GetMV("MV_NUMBORR"),6)
	cNumBor := Replicate("0",6-Len(Alltrim(cNumBor)))+Alltrim(cNumBor)
	While !MayIUseCode("SE1"+xFilial("SE1")+cNumBor)  //verifica se esta na memoria, sendo usado
		cNumBor := Soma1(cNumBor)
	EndDo

	//Verifica se o numero do bordero já foi usando para evitar erro de chave duplicada
	dbSelectArea("SEA")   
	SEA->(dbSetOrder(1))	
	While SEA->(dbseek(xfilial("SEA")+cNumBor))
		cNumBor := Soma1(cNumBor)
	EndDo		
	
	dbSelectArea("SEE")   // Tabela de Bancos 
	dbSetOrder(1)	
	//If SEE->(DbSeek(xfilial("SEE") + aTitBor[nCnta][1] + aTitBor[nCnta][2] + aTitBor[nCnta][3] + "001")) 
	If SEE->(DbSeek(xfilial("SEE") + aTitBor[nCnta][1] + aTitBor[nCnta][2] + AvKey(aTitBor[nCnta][3],"EE_CONTA") + "001")) 
	
		aTitFat  := ACLONE(aTitBor[nCnta][6])
		
		For nCntb:=1 to len(aTitFat)
			SE1->(dbGoto(aTitFat[nCntb]))	
			IF SE1->(!EOF())	
				
				RecLock("SEA",.T.)
				SEA->EA_FILIAL  := xFilial("SEA")
				SEA->EA_NUMBOR  := cNumBor
				SEA->EA_DATABOR := dDatabase
				SEA->EA_PORTADO := SEE->EE_CODIGO
				SEA->EA_AGEDEP  := SEE->EE_AGENCIA
				SEA->EA_NUMCON  := SEE->EE_CONTA
				SEA->EA_NUM 	:= SE1->E1_NUM
				SEA->EA_PARCELA := SE1->E1_PARCELA
				SEA->EA_PREFIXO := SE1->E1_PREFIXO
				SEA->EA_TIPO	:= SE1->E1_TIPO
				SEA->EA_CART	:= "R"
				SEA->EA_SITUACA := "0"
				SEA->EA_SITUANT := SE1->E1_SITUACA
				SEA->EA_FILORIG := SE1->E1_FILORIG
				SEA->EA_PORTANT := SE1->E1_PORTADO
				SEA->EA_AGEANT  := SE1->E1_AGEDEP
				SEA->EA_CONTANT := SE1->E1_CONTA
				SEA->EA_ORIGEM := "FINA061"
				MsUnlock()
				
				RecLock("SE1",.F.)
				SE1->E1_PORTADO := SEE->EE_CODIGO
				SE1->E1_AGEDEP  := SEE->EE_AGENCIA
				SE1->E1_CONTA	:= SEE->EE_CONTA
				SE1->E1_SITUACA := "1" 				//TODO - Avaliar tipo de cobrança
				SE1->E1_CONTRAT := ""
				SE1->E1_NUMBOR  := cNumBor
				SE1->E1_DATABOR := dDataBase
				SE1->E1_MOVIMEN := dDataBase

				//DDA - Debito Direto Autorizado
				If SE1->E1_OCORREN $ "53/52"
					SE1->E1_OCORREN := "01"
				Endif
				
				MsUnlock()				
				
			endif
		Next
		
		IF SEE->EE_CODIGO == "237"
			cArqRem:= aTitBor[nCnta][5] + "CB" + LEFT(STRTRAN(DTOC(DATE()),"/",""),4) + cNumBor + "SP.REM"
		ELSEIF SEE->EE_CODIGO == "341"
			cArqRem:= aTitBor[nCnta][5] + "CB" + LEFT(STRTRAN(DTOC(DATE()),"/",""),4) + cNumBor + "SP.TXT"
		ENDIF
		
		FERASE(cArqRem)
		
		pergunte("AFI150",.F.)
					
		MV_PAR01:= cNumBor		 		// Do Bordero 		   
		MV_PAR02:= cNumBor		 		// Ate o Bordero 	   
		MV_PAR03:= aTitBor[nCnta][4]	// Arq.Config 		 						   
		MV_PAR04:= cArqRem				// Arq. Saida   	   
		MV_PAR05:= SEE->EE_CODIGO		// Banco     		   
		MV_PAR06:= SEE->EE_AGENCIA		// Agenciao     	   
		MV_PAR07:= SEE->EE_CONTA		// Conta   		   
		MV_PAR08:= SEE->EE_SUBCTA		// Sub-Conta  		   
		MV_PAR09:= 1		 			// Cnab 1 / Cnab 2    
		MV_PAR10:= 2		 			// Considera Filiais  
		MV_PAR11:= CFILANT		 		// De Filial   	   
		MV_PAR12:= CFILANT		 		// Ate Filial         
		MV_PAR13:= 3		 			// Quebra por ?	   
		MV_PAR14:= 2		 			// Seleciona Filial?  
			
		ProcLogAtu("INICIO")
		
		fa150Gera("SE1")

		ProcLogAtu("FIM")		
			
		PutMv("MV_NUMBORR",cNumBor)		
								
	ENDIF
Next

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK01] Fim CNAB de cobrança.")

RETURN
/*/{Protheus.doc} CJBK01PP
Adiciona pipe a cada 100 caracter
@author Carlos Henrique
@since 01/01/2015
@version 12
@param cValAjuste, characters, descricao
@type function
/*/
STATIC FUNCTION CJBK01PP(cValAjuste)
LOCAL aVlrAjuste	:= STRTOKARR(cValAjuste," ",.T.)
Local nCheckPoint	:= 100
Local cValRet		:= ""
Local nCnt			:= 0

//Adiciona pipe a cada 100 caracter
FOR nCnt:=1 to len(aVlrAjuste)
	IF LEN(TRIM(cValRet+aVlrAjuste[nCnt])) >= nCheckPoint
		cValRet+= "|" + aVlrAjuste[nCnt] + " "
		nCheckPoint+= 100
	ELSE
		cValRet+= aVlrAjuste[nCnt] + " "	 
	Endif
NEXT nCnt

RETURN cValRet	
/*/{Protheus.doc} CJBK01BF
Rotina de tratamento do banco de faturamento
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK01BF(cBcoFat,nValor,cConFat,cIdCont)

if ZC4->(DbSeek(xFilial("ZC4")+cConFat+cIdCont))
	
	cBcoFat:= ZC4->ZC4_CODBCO
	
	if nValor >= ZC4->ZC4_VLREXC
		cBcoFat := IF(EMPTY(ZC4->ZC4_BCOEXC),cBcoFat,ZC4->ZC4_BCOEXC)
	endif

else

	IF EMPTY(cBcoFat)
		IF nValor > SuperGetMV("CI_VLRBCO",.T.,250)
			cBcoFat:= ALLTRIM(SuperGetMV("CI_BCOMIN",.T.,"237"))
		ELSE
			cBcoFat:= ALLTRIM(SuperGetMV("CI_BCOMAX",.T.,"341"))
		ENDIF	
	ENDIF

endif

RETURN cBcoFat
/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
Static Function Scheddef()
Local aParam := {"P","CJOBK01","",{},""}    
Return aParam


User Function ProcCTB()

LOCAL cPadrao  := "X05"   
LOCAL cLote    := "990001"
LOCAL cArquivo := ''
LOCAL nTotal   := 0
LOCAL nHdlPrv  := 0
Local dBkpDta  := DDATABASE
Local cTDt     := ""
Local aDtRec   := {}
Local nX       := 0
Local nY       := 0
Local nPos     := 0

IF VerPadrao(cPadrao)

	nPos := aScan( aDtRec, {|X| X[1] == SE1->E1_EMISSAO } )
	
	If nPos == 0
	
	    SE1->( aAdd( aDtRec, { E1_EMISSAO, { SE1->(RecNo())} } ) )
	
	Else
	
	    SE1->( aAdd( aDtRec[ nPos, 2 ], SE1->(RecNo()) ) )
	
	EndIf

    For nX := 1 To Len( aDtRec )

        DDATABASE:= aDtRec[ nX, 1 ] 
        nHdlPrv  := HeadProva(cLote,"CJOBK01",Substr(cUsuario,7,6),@cArquivo)

        For nY := 1 To Len( aDtRec[ nX, 2 ] )

            SE1->( DbGoto(aDtRec[nX,2,nY] ) )

            RecLock("SE1",.F.)
            SE1->E1_LA='S'
            MsUnLock()

            nTotal += DetProva( nHdlPrv,;
                cPadrao,;
                "CJOBK01",;
                cLote,;
      /*nLinha*/,;
      /*lExecuta*/,;
      /*cCriterio*/,;
      /*lRateio*/,;
      /*cChaveBusca*/,;
      /*aCT5*/,;
      /*lPosiciona*/,;
      /*aFlagCTB*/,;
      /*aTabRecOri*/,;
      /*aDadosProva*/ )	


        Next nY

        IF nTotal > 0
            RodaProva(nHdlPrv,nTotal)
            cA100Incl( cArquivo,;
                nHdlPrv,;
                3,;
                cLote,;
                .F.,;
                .T.,;
      /*cOnLine*/,;
      /*dData*/,;
      /*dReproc*/,;
      /*aFlagCTB*/,;
      /*aDadosProva*/,;
      /*aDiario*/)
        EndIf

        Next nX

    End If

    DDATABASE:= dBkpDta

Return

Static Function RetTpCont(cFilZC0, cIdCont)

Local aArea   := GetArea()
Local aTpCont := {}

DbSelectArea("ZC0")
DbSetOrder(1)

If DbSeek(xFilial('ZC0') + cIdCont)
	AADD(aTpCont,{ZC0->ZC0_TIPCON,ZC0_TIPAPR})
EndIf

RestArea(aArea)

Return aTpCont

/*/{Protheus.doc} CJBKFATAPD()
Verifica se eh um faturamento de aprendiz/empregador
@author  	Marcelo Moraes
@since     	16/10/2020
@version  	P.12.1.17      
@return   	Nenhum 
/*/
Static Function CJBKFATAPD(_cFilial,cIdFatu)

local cRet        := ""
local aArea 	  := GetArea()
local cAliasZC5   := GetNextAlias()
local cQry 		  := ""

cQry += " SELECT ZC5_LOTE FROM "+RetSqlName("ZC5")
cQry += " WHERE "
cQry += " ZC5_FILIAL='"+Alltrim(_cFilial)+"' "
cQry += " AND ZC5_IDFATU='"+Alltrim(cIdFatu)+"' "
cQry += " AND (ZC5_LOTE LIKE '%FI%' OR ZC5_LOTE LIKE '%FF%') "

cQry := ChangeQuery(cQry)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasZC5,.T.,.T.)

if (cAliasZC5)->(!EOF()) 

    cRet := "S"

endif

(cAliasZC5)->(DbCloseArea())

restarea(aArea)

return(cRet)

user function CJBK01RC(nValor, cCliente, cLoja, cBanco, cAgencia, cConta, dVencrea, cNumSeq, lTela, cCompet, cIdCnt)

	local oPrinter
	local cArquivo
	local oFont1
	local oFont2
	local oFont3
	local cMes
	local cTmpPath 	:= ""
	local cDirRel
	local cCgc
	default lTela 	:= .f.

	dbselectArea("SA1")

	SA1->(dbSetOrder(1))

	SA1->(msSeek(xFilial("SA1") + padr(cCliente, tamsx3("A1_COD")[1]) + alltrim(cLoja)))

	cArquivo := alltrim(SA1->A1_CGC) + "_" + cCompet + "_" + cNumSeq + "_" + alltrim(cIdCnt)

	if lTela
		oPrinter := FWMSPrinter():New(cArquivo, IMP_PDF, .T., "\spool\",.T.,,,,.T.,,,.F.)
	else
		oPrinter := FWMSPrinter():New(cArquivo, IMP_PDF, .T., "\system\recibos\",.T.,,,,.T.,,,.F.)
	endif

	oPrinter:SetResolution(78)
	oPrinter:SetPortrait()
	oPrinter:SetPaperSize(DMPAPER_A4)
	oPrinter:SetMargin(10,10,10,10) // nEsquerda, nSuperior, nDireita, nInferior

	oPrinter:lServer 	:= .T. 
	oPrinter:CPRINTER	:="PDF"

	if lTela
		oPrinter:cPathPDF 	:= "\spool\" 
	else
		oPrinter:cPathPDF 	:= "\system\recibos\" 	
	endif

	oFont1 := TFont():New( "Arial", , -14, .T.)
	oFont1:Bold := .T.
	
	oFont2 := TFont():New( "Arial", , -18, .T.)
	oFont2:Bold := .T.

	oFont3 := TFont():New( "Arial", , -14, .T.)

	dbSelectArea("SA1")

	SA1->(dbSetOrder(1))

	SA1->(msseek(xFilial("SA1") + cCliente + cLoja))

	oPrinter:StartPage()
	
	oPrinter:SayBitmap( 50, 1000,"logo_ciee.png", 460, 160)
	oPrinter:Say( 240, 1600, "Nº " + cNumSeq,oFont2,,CLR_BLACK)
	
	oPrinter:Say( 400, 200 , "Valor: R$ " + alltrim(Transform(nValor,"@E 999,999.99")),oFont1,,CLR_BLACK)
	oPrinter:Say( 460, 200 , "Recebemos de: " + ALLTRIM(SA1->A1_NOME),oFont1,,CLR_BLACK)
	oPrinter:Say( 520, 200 , "CNPJ/CPF: " + ALLTRIM(SA1->A1_CGC),oFont1,,CLR_BLACK)
	oPrinter:Say( 520, 1300, "Tipo de empresa: ",oFont1,,CLR_BLACK)
	oPrinter:Say( 580, 200 , "Endereço: " + ALLTRIM(SA1->A1_END),oFont1,,CLR_BLACK)
	oPrinter:Say( 580, 1300, "CEP: " + ALLTRIM(SA1->A1_CEP),oFont1,,CLR_BLACK)
	oPrinter:Say( 640, 200 , "Municipio: " + ALLTRIM(SA1->A1_MUN),oFont1,,CLR_BLACK)
	oPrinter:Say( 640, 1300, "U.F.: " + ALLTRIM(SA1->A1_EST),oFont1,,CLR_BLACK)

	oPrinter:Say( 800, 120, "REFERENTE:  Receita : 019-PROGRAMA ADOLESCENTE APRENDIZ-FOLHA DE PAGAMENTO  Ref.: " + cValtochar(month(dDataBase)) + "/" + cValtoChar(year(dDataBase)),oFont3,,CLR_BLACK)

	oPrinter:Say( 850, 120, "Valor: R$ " + cValtochar(nValor),oFont3,,CLR_BLACK)

	oPrinter:Say( 900, 120, "Recebido através de: Deposito  Banco: " + alltrim(cBanco) + "  No. Ag.: " + alltrim(cAgencia) + "  C.Cor.: " + alltrim(cConta) + "  Data: " + Dtoc(dVencrea),oFont3,,CLR_BLACK)

	if     Month(dDataBase) == 1
		cMes := "Janeiro"
	elseif Month(dDataBase) == 2
		cMes := "Fevereiro"
	elseif Month(dDataBase) == 3
		cMes := "Março"
	elseif Month(dDataBase) == 4
		cMes := "Abril"
	elseif Month(dDataBase) == 5
		cMes := "Maio"
	elseif Month(dDataBase) == 6
		cMes := "Junho"
	elseif Month(dDataBase) == 7
		cMes := "Julho"
	elseif Month(dDataBase) == 8
		cMes := "Agosto"
	elseif Month(dDataBase) == 9
		cMes := "Setembro"
	elseif Month(dDataBase) == 10
		cMes := "Outubro"
	elseif Month(dDataBase) == 11
		cMes := "Novembro"
	elseif Month(dDataBase) == 12
		cMes := "Dezembro"
	endif

	oPrinter:Say( 1300, 1800, "São Paulo, " + cValtoChar(day(dDataBase)) + " de " + cMes + " de "  + cValtoChar(year(dDataBase)),oFont3,,CLR_BLACK)
	oPrinter:SayBitmap( 1400, 120,"rodape_recibo.png", 2400, 1500)

	oPrinter:EndPage()

	if !lTela
		oPrinter:SetViewPDF(.F.)
		oPrinter:Preview(AllTrim(GetProfString(GetPrinterSession(),"DEFAULT","",.T.)))

	else

		cTmpPath 	:= GetTempPath()

		cDirRel := "\spool\" + cArquivo + ".pdf"
		
		oPrinter:Preview()
		CpyS2T(cDirRel, cTmpPath , .F. )
		ShellExecute("OPEN",cTmpPath+cArquivo + ".pdf","","",5)
	endif

	FreeObj(oPrinter)
	oPrinter := Nil			

return

/*/{Protheus.doc} GeraRecAcumulado
Verifica se o recibo deverá ser gerado de forma acumulada (repasse + CI)
@author marcelo.moraes
@since 17/11/2020
@version undefined
@type function
/*/
STATIC FUNCTION GeraRecAcumulado()

local lRet        := .F.
local cConCob     := ""
local cConFat     := ""
local aGeraRec    := ""

cConCob  := GetAdvFVal("ZCI","ZCI_IDCOBR" ,XFILIAL("ZCI")+SE1->E1_XIDCNT+SE1->E1_XIDLOC,3) 

//Busca Configuração do faturamento
cConFat   := GetAdvFVal("ZC4","ZC4_IDFATU" ,XFILIAL("ZC4")+SE1->E1_XIDCNT,2)

//Busca os campos que informam se o recibo deve ser gerado somando valor do repasse + valor da CI
aGeraRec := GetAdvFVal("ZC3",{"ZC3_CISEPA","ZC3_EMIREC"} ,XFILIAL("ZC3")+cConCob+SE1->E1_XIDCNT+cConFat,1)

if len(aGeraRec) > 0
	if aGeraRec[1] == "1" .and. aGeraRec[2] == "1" //CI Separada=SIM e Emite Recibo=SIM
		lRet := .T.
	endif
endif

return(lRet)

/*/{Protheus.doc} SomaVlrRec
Soma o valor do repasse + CI
@author marcelo.moraes
@since 17/11/2020
@version undefined
@type function
/*/
STATIC FUNCTION SomaVlrRec()

local nRet 		:= 0
local cQry      := ""
local cAliasSE1 := GetNextAlias()

cQry += " SELECT * FROM (SELECT "  
cQry += " E1_XIDCNT, E1_XIDLOC,  E1_XCOMPET, COUNT(*) QTREG, SUM(E1_VALOR) VALOR "
cQry += " FROM " + RetSqlName("SE1")
cQry += " WHERE " 
cQry += " D_E_L_E_T_='' "
cQry += " AND E1_XIDCNT='"+ALLTRIM(SE1->E1_XIDCNT)+"' "
cQry += " AND E1_XIDLOC='"+ALLTRIM(SE1->E1_XIDLOC)+"' "
cQry += " AND E1_XCOMPET='"+ALLTRIM(SE1->E1_XCOMPET)+"' "
cQry += " AND E1_XAPD='S' "
cQry += " GROUP BY " 
cQry += " E1_XIDCNT, E1_XIDLOC,  E1_XCOMPET) AS TABELA "

cQry := ChangeQuery(cQry)

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAliasSE1,.T.,.T.)

if (cAliasSE1)->(!EOF()) .and. (cAliasSE1)->QTREG > 1
	nRet := (cAliasSE1)->VALOR  	
endif

(cAliasSE1)->(DbCloseArea())

return(nRet)

/*/{Protheus.doc} EmiteRecibo
Valida se deverá ser emitido recibo para o repasse de faturamento do aprendiz/empregador
@author marcelo.moraes
@since 17/11/2020
@version undefined
@type function
/*/
STATIC FUNCTION EmiteRecibo()

local lRet        := .F.
local cConCob     := ""
local cConFat     := ""

//Busca Configuração de cobrança
cConCob  := GetAdvFVal("ZCI","ZCI_IDCOBR" ,XFILIAL("ZCI")+SE1->E1_XIDCNT+SE1->E1_XIDLOC,3) 

//Busca Configuração do faturamento
cConFat   := GetAdvFVal("ZC4","ZC4_IDFATU" ,XFILIAL("ZC4")+SE1->E1_XIDCNT,2)

//valida se deve ou não emitir recibo
if GetAdvFVal("ZC3","ZC3_EMIREC",XFILIAL("ZC3")+cConCob+SE1->E1_XIDCNT+cConFat,1) == "1" //Emite Recibo=Sim
	lRet := .T.
endif

return(lRet)


