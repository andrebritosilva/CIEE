#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK07
JOB de processamento das filas KAIROS
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
User function CJOBK07()
Local lJob		:= GetRemoteType() == -1 // Verifica se é job
Local cEmpInt	:= CEMPANT
Local cFilInt	:= CFILANT
Local nOpca		:= 0

IF !lJob	
	IF MSGYESNO("Confirma o processamento da Fila Kairós ?")
		nOpca:= 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK07] Iniciando processamento via schedule.")
	nOpca:= 1		                                                                                                          
ENDIF

IF !LockByName("CJOBK07",.T.,.T.)
	nOpca:= 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK07] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK07PR(lJob) },,"Realizando processamento da Fila Kairós, aguarde...")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK07] Processo Iniciado para "+cEmpInt+"-"+cFilInt)
		CJBK07PR(lJob) 
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK07] Processo Finalizado para "+cEmpInt+"-"+cFilInt)	
	ENDIF
	
	UnLockByName("CJOBK07",.T.,.T.)	
	
ENDIF

RETURN

/*/{Protheus.doc} CJBK07PR
Rotina de processamento da Fila KAIROS
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK07PR(lJob)

Local cTab

Local oObj     := Nil
//Local nCnt     := 0
//Local nQtd     := 0
//Local nQTdFila := 0

/*

// Consumir as filas do Rabbit
cTab := GetNextAlias()
BeginSql Alias cTab
	SELECT *
	FROM %TABLE:ZCP% ZCP
	WHERE ZCP_FILIAL = %xfilial:ZCP%
	  AND ZCP_TIPO = '1'
	  AND ZCP_TIPRMQ = '1'
	  AND ZCP_STATUS = '1'
	  AND ZCP.D_E_L_E_T_ = ''
	ORDER BY ZCP_ORDEM
EndSql

//aRet:= GETLastQuery()[2]

IF (cTab)->(!EOF())

	WHILE (cTab)->(!EOF())
		
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK07] INICIO CONSUMO FILA:" + TRIM((cTab)->ZCP_FILA))

		oObj := Rabbit():New((cTab)->ZCP_URLRMQ,;
			 				 (cTab)->ZCP_TCPRMQ,;
							 (cTab)->ZCP_USRRMQ,;
							 (cTab)->ZCP_PSWRMQ)

		IF !EMPTY(oObj:Error())

			IF lJob
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK07] " + oObj:Error())
			ELSE
				MSGALERT( oObj:Error() )
			ENDIF

			(cTab)->(dbSkip())
			loop
		ENDIF

		oObj:setFila( (cTab)->ZCP_TIPO,;
					  (cTab)->ZCP_FILA)

		IF !EMPTY(oObj:Error())
			
			IF lJob
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK07] " + oObj:Error())
			ELSE
				MSGALERT( oObj:Error() )
			ENDIF

			(cTab)->(dbSkip())
			loop
		ENDIF
		
//		For nCnt:= 1 to oObj:MessageCount()
//			oObj:Receiver()
//			oObj:BasicAck(oObj:Tag(),.F.)
//		next
		
//		CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK07] FIM CONSUMO FILA:" + TRIM((cTab)->ZCP_FILA))

		nQTdFila := oObj:MessageCount()
		
		Freeobj(oObj)

		oObj := Nil
		nQtd := 0

		oObj := Rabbit():New((cTab)->ZCP_URLRMQ,;
							(cTab)->ZCP_TCPRMQ,;
							(cTab)->ZCP_USRRMQ,;
							(cTab)->ZCP_PSWRMQ)

		IF !EMPTY(oObj:Error())

			IF lJob
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK07] " + oObj:Error())
			ELSE
				MSGALERT( oObj:Error() )
			ENDIF

			(cTab)->(dbSkip())
			loop
		ENDIF

		oObj:setFila( (cTab)->ZCP_TIPO,;
					  (cTab)->ZCP_FILA)

		IF !EMPTY(oObj:Error())
			
			IF lJob
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK07] " + oObj:Error())
			ELSE
				MSGALERT( oObj:Error() )
			ENDIF

			(cTab)->(dbSkip())
			loop
		ENDIF

		For nCnt:= 1 to nQTdFila

			nQtd++
			
			oObj:Receiver()
			oObj:BasicAck(oObj:Tag(),.F.)
			
			if nQtd > GetMv("CI_QTRABBI")
				
				Freeobj(oObj)

				oObj := Nil

				nQtd := 0

				oObj := Rabbit():New((cTab)->ZCP_URLRMQ,;
									(cTab)->ZCP_TCPRMQ,;
									(cTab)->ZCP_USRRMQ,;
									(cTab)->ZCP_PSWRMQ)
			
				IF !EMPTY(oObj:Error())

					IF lJob
						CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK07] " + oObj:Error())
					ELSE
						MSGALERT( oObj:Error() )
					ENDIF

					loop
				ENDIF

				oObj:setFila( (cTab)->ZCP_TIPO,;
							(cTab)->ZCP_FILA)

				IF !EMPTY(oObj:Error())
					
					IF lJob
						CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK07] " + oObj:Error())
					ELSE
						MSGALERT( oObj:Error() )
					ENDIF

					loop
				ENDIF

			endif

		next

		Freeobj(oObj)

		CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK07] FIM CONSUMO FILA:" + TRIM((cTab)->ZCP_FILA))

		(cTab)->(dbSkip())
	ENDDO
ENDIF

(cTab)->(dbCloseArea())

*/

// Processar as filas do Rabbit
cTab := GetNextAlias()
BeginSql Alias cTab
	SELECT *
	FROM %TABLE:ZCP% ZCP
	WHERE ZCP_FILIAL = %xfilial:ZCP%
	  AND ZCP_TIPO = '1'
	  AND ZCP_TIPRMQ = '1'
	  AND ZCP_STATUS = '1'
	  AND ZCP.D_E_L_E_T_ = ''
	ORDER BY ZCP_ORDEM
EndSql

//aRet:= GETLastQuery()[2]

IF (cTab)->(!EOF())

	WHILE (cTab)->(!EOF())
		
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK07] INICIO PROCESSAMENTO FILA:" + TRIM((cTab)->ZCP_FILA))

		oObj := Rabbit():New((cTab)->ZCP_URLRMQ,;
			 				 (cTab)->ZCP_TCPRMQ,;
							 (cTab)->ZCP_USRRMQ,;
							 (cTab)->ZCP_PSWRMQ)

		IF !EMPTY(oObj:Error())

			IF lJob
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK07] " + oObj:Error())
			ELSE
				MSGALERT( oObj:Error() )
			ENDIF

			(cTab)->(dbSkip())
			loop
		ENDIF

		// Processa fila
		oObj:Processa((cTab)->ZCP_GRID,;
					  (cTab)->ZCP_FILA,;
					  (cTab)->ZCP_FUNPRO,;
					  (cTab)->ZCP_URLCAL,;
					  (cTab)->ZCP_USRCAL,;
					  (cTab)->ZCP_PSWCAL,;
					  (cTab)->ZCP_PTOKEN,;
					  (cTab)->ZCP_FILRET,;
					  (cTab)->ZCP_ENVDW3,;
					  (cTab)->ZCP_FILDW3,;
					  (cTab)->ZCP_TIPO)

		CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK07] FIM PROCESSAMENTO FILA:" + TRIM((cTab)->ZCP_FILA))
		
		Freeobj(oObj)

		(cTab)->(dbSkip())
	ENDDO
ENDIF

(cTab)->(dbCloseArea())

Return

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
Static Function Scheddef()
Local aParam := {"P","CJOBK07","",{},""}    
Return aParam

/*/{Protheus.doc} TSTFILAK
Rotina de teste
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
user function TSTFILAK()
Local oObj    := nil
Local nCnt    := 0

RpcSetType(3)
IF RPCSetEnv("01","0001")   //RPCSetEnv("99","01") 
	
	__CINTERNET:= NIL
	
	//--------------------
	//Gera fila de teste
	//--------------------
	oObj:= Rabbit():New("cross-cluster-rabbit-elb-hfx-e30198565ffcfb8d.elb.sa-east-1.amazonaws.com","5672","Kairos","admK@ir05")

	IF !EMPTY(oObj:Error())
		conout( oObj:Error() )
	else

		oObj:setFila("1","teste-danilo")

		IF !EMPTY(oObj:Error())
			conout( oObj:Error() )
		else        
			For nCnt:= 1 to 20
				oObj:Sender('{"tipoEnvio":"UNIDADES_CIEE","operacaoEnvio": "POST","idEntidade":' + CVALTOCHAR(nCnt) +',"url":"/unit/unidades-ciee/' + CVALTOCHAR(nCnt) +'","idLog":' + CVALTOCHAR(nCnt) +'}')
			next  
		ENDIF       

	ENDIF       

	Freeobj(oObj)

ENDIF

RpcClearEnv()

Return