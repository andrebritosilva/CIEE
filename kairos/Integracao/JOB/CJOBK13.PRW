#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK13
JOB de consumo das filas KAIROS
@author danilo.grodzicki
@since 03/09/2020
@version undefined
@type function
/*/
User function CJOBK13()

Local lJob    := GetRemoteType() == -1  // Verifica se é job
Local cEmpInt := CEMPANT
Local cFilInt := CFILANT
Local nOpca   := 0

IF !lJob
	IF MSGYESNO("Confirma o consumo da Fila Kairós ?")
		nOpca := 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK13] Iniciando processamento via schedule.")
	nOpca := 1
ENDIF

IF !LockByName("CJOBK13",.T.,.T.)
	nOpca := 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK13] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK13PR(lJob) },,"Realizando consumo da Fila Kairós, aguarde...")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK13] INICIO CONSUMO FILA para "+cEmpInt+"-"+cFilInt)
		CJBK13PR(lJob)
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK13] FIM CONSUMO FILA para "+cEmpInt+"-"+cFilInt)
	ENDIF
	
	UnLockByName("CJOBK13",.T.,.T.)

ENDIF

RETURN

/*/{Protheus.doc} CJBK13PR
Rotina de consumo da Fila KAIROS
@author danilo.grodzicki
@since 03/09/2020
@version undefined
@type function
/*/
STATIC FUNCTION CJBK13PR(lJob)

Local cTab

Local oObj     := Nil
Local nCnt     := 0
Local nQtd     := 0
Local nQTdFila := 0

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
		
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK13] INICIO CONSUMO FILA:" + TRIM((cTab)->ZCP_FILA))

		oObj := Rabbit():New((cTab)->ZCP_URLRMQ,;
			 				 (cTab)->ZCP_TCPRMQ,;
							 (cTab)->ZCP_USRRMQ,;
							 (cTab)->ZCP_PSWRMQ)

		IF !EMPTY(oObj:Error())

			IF lJob
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK13] " + oObj:Error())
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
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK13] " + oObj:Error())
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
		
		CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK13] FIM CONSUMO FILA:" + TRIM((cTab)->ZCP_FILA))

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
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK13] " + oObj:Error())
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
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK13] " + oObj:Error())
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
						CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK13] " + oObj:Error())
					ELSE
						MSGALERT( oObj:Error() )
					ENDIF

					loop
				ENDIF

				oObj:setFila( (cTab)->ZCP_TIPO,;
							(cTab)->ZCP_FILA)

				IF !EMPTY(oObj:Error())
					
					IF lJob
						CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJOBK13] " + oObj:Error())
					ELSE
						MSGALERT( oObj:Error() )
					ENDIF

					loop
				ENDIF

			endif

		next

		Freeobj(oObj)

		CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK13] FIM CONSUMO FILA:" + TRIM((cTab)->ZCP_FILA))

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
Local aParam := {"P","CJOBK13","",{},""}
Return aParam