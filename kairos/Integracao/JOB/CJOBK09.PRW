#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK09
JOB de processamento de envio das filas para o KAIROS
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
User function CJOBK09()
Local lJob		:= GetRemoteType() == -1 // Verifica se é job
Local cEmpInt	:= CEMPANT
Local cFilInt	:= CFILANT
Local nOpca		:= 0

IF !lJob	
	IF MSGYESNO("Confirma o processamento de envio das filas para o KAIROS ?")
		nOpca:= 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Iniciando processamento via schedule.")
	nOpca:= 1		                                                                                                          
ENDIF

IF !LockByName("CJOBK09",.T.,.T.)
	nOpca:= 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK09PR(lJob) },,"Realizando processamento de envio das filas para o KAIROS, aguarde...")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Processo Iniciado para "+cEmpInt+"-"+cFilInt)
		CJBK09PR(lJob) 
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Processo Finalizado para "+cEmpInt+"-"+cFilInt)	
	ENDIF
	
	UnLockByName("CJOBK09",.T.,.T.)	
	
ENDIF

RETURN 
/*/{Protheus.doc} CJBK09PR
Rotina de processamento de envio das filas para o KAIROS
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK09PR(lJob)
Local cZCP  := GetNextAlias()
Local cZCQ  := ""
Local nX    := 0
Local aFila := {}

CJBK09RESP()  // Função que processa o envio das respostas para o Kairós

BeginSql Alias cZCP
    SELECT * FROM %TABLE:ZCP% ZCP 
    WHERE ZCP_FILIAL=%xfilial:ZCP%
        AND ZCP_TIPO='1'
        AND ZCP_TIPRMQ='2'  
        AND ZCP_STATUS='1' 
        AND ZCP.D_E_L_E_T_ =''
    ORDER BY ZCP_ORDEM    		
EndSql

//aRet:= GETLastQuery()[2]
IF (cZCP)->(!EOF()) 

    WHILE (cZCP)->(!EOF())		
        
        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] INICIO FILA:" + TRIM((cZCP)->ZCP_FILA))
   
        cZCQ:= GetNextAlias()
        BeginSql Alias cZCQ
            SELECT R_E_C_N_O_ AS RECZCQ FROM %TABLE:ZCQ% ZCQ 
            WHERE ZCQ_FILIAL=%xfilial:ZCQ% 
                AND ZCQ_STATUS='0'
                AND ZCQ_FILA=%Exp:(cZCP)->ZCP_FILA% 
                AND ZCQ_CODE='' 
                AND ZCQ.D_E_L_E_T_ =''    
        EndSql   

        //aRet:= GETLastQuery()[2]
        WHILE (cZCQ)->(!EOF())	 
            AADD(aFila,(cZCQ)->RECZCQ)                        
        (cZCQ)->(dbSkip())	
        END  
        
        (cZCQ)->(dbCloseArea())    

        IF !EMPTY(aFila)
            
            //Processamento em grid
            IF (cZCP)->ZCP_GRID == "1" 
                
                oGrid := GridClient():New()
                
                lRet := oGrid:BatchExec("U_CJBK09AMB",{cEmpAnt,cFilAnt,""},"U_CJBK09RET",aFila)

                If !lRet .and. Empty(oGrid:aGridThreads)
                    CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Nenhum Agente do GRID disponivel no Momento.")
                EndIf

                If !empty(oGrid:aErrorProc)               
                    varinfo('Lista de Erro',oGrid:aErrorProc)   
                Endif   

                If !empty(oGrid:aSendProc)                 
                    varinfo('Não processado',oGrid:aSendProc)   
                Endif 
            else
                For nX:= 1 to len(aFila)
                    U_CJBK09AMB({cEmpAnt,cFilAnt,"U_CJBK09RET("+CVALTOCHAR(aFila[nX])+")"})
                Next	            	
            endif		
        else
            CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Nenhuma fila pendente de envio")
        endif        

        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] FIM FILA:" + TRIM((cZCP)->ZCP_FILA))              

    (cZCP)->(dbSkip())	
    END  
ELSE

ENDIF    

(cZCP)->(dbCloseArea())	

Return
/*/{Protheus.doc} CJBK09AMB
Prepara ambiente GRID
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
USER Function CJBK09AMB(aParms)
Local cEmpParm:= aParms[1]	// Empresa --> cEmpAnt
Local cFilParm:= aParms[2]	// Filial  --> cFilAnt
Local cFunExec:= aParms[3]	// Rotina  ---> Apenas startjob

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Preparando ambiente")

RpcSetType(3)
RPCSetEnv(cEmpParm,cFilParm) 

IF !EMPTY(cFunExec)
	&(cFunExec)
ENDIF

Return .T.
/*/{Protheus.doc} CJBK09RET
Rotina de retono das fila
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CJBK09RET(nRecno)
Local cTEnvKAI:= AllTrim(SuperGetMV("CI_TENVKAI",,"1")) //Define o tipo de integração o KAIROS => 1=Fila;2=Rest

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Inicio envio RECNO:" + CVALTOCHAR(nRecno) )

dbselectarea("ZCQ")
ZCQ->(dbGoto(nRecno))	
IF ZCQ->(!EOF())

    //Envio via FILA RABBITMQ
    IF cTEnvKAI == "1"

        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Processando via RabbitMQ.")
        CJBK09RMQ()
    
    //Envio via REST
    ELSEIF cTEnvKAI == "2"

        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Processando via rest.")
        CJBK09API()
    
    ELSE
        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Tipo de envio o KAIROS invalido:" + cTEnvKAI)
    ENDIF      

ENDIF

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Fim envio RECNO:" + CVALTOCHAR(nRecno) )

Return
/*/{Protheus.doc} CJBK09RMQ
Rotina de integração via RabbitMQ
@author carlos.henrique
@since 01/01/2015
@version undefined
@param aBlocoMsg, array, descricao
@type function
/*/
Static Function CJBK09RMQ()
Local cTab:= GetNextAlias()
Local oObj:= nil
Local cVerbo:= ""

BeginSql Alias cTab
    SELECT * FROM %TABLE:ZCP% ZCP 
    WHERE ZCP_FILIAL=%xfilial:ZCP%
        AND ZCP_TIPO='1'
        AND ZCP_TIPRMQ='2'  
        AND ZCP_STATUS='1' 
        AND ZCP_FILA=%Exp:ZCQ->ZCQ_FILA% 
        AND ZCP.D_E_L_E_T_ =''
    ORDER BY ZCP_ORDEM    		
EndSql

//aRet:= GETLastQuery()[2]
IF (cTab)->(!EOF()) 

    oObj:= Rabbit():New((cTab)->ZCP_URLRMQ,;
                        (cTab)->ZCP_TCPRMQ,;
                        (cTab)->ZCP_USRRMQ,;
                        (cTab)->ZCP_PSWRMQ)

    IF !EMPTY(oObj:Error())

        RECLOCK("ZCQ",.F.)
            ZCQ->ZCQ_STATUS := "2"
            ZCQ->ZCQ_MSG    := oObj:Error()
        MSUNLOCK()    
    ELSE                                    

        oObj:setFila( (cTab)->ZCP_TIPO,; 
                        (cTab)->ZCP_FILA)

        IF !EMPTY(oObj:Error())            
            RECLOCK("ZCQ",.F.)
                ZCQ->ZCQ_STATUS := "2"
                ZCQ->ZCQ_MSG    := oObj:Error()
            MSUNLOCK()    
        ELSE

            CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK09] Processando via Rabbit.")

            IF ZCQ->ZCQ_OPEENV == "1"
                cVerbo:="POST"
            ELSEIF ZCQ->ZCQ_OPEENV == "2"
                cVerbo:="PUT"
            ELSEIF ZCQ->ZCQ_OPEENV == "3"    
                cVerbo:="DELETE"
            ENDIF

            oObj:Sender(TRIM(ZCQ->ZCQ_JSON))  

            IF !EMPTY(oObj:Error())
                RECLOCK("ZCQ",.F.)
                    ZCQ->ZCQ_STATUS := "2"
                    ZCQ->ZCQ_MSG    := oObj:Error()
                MSUNLOCK()                     
            ELSE
                RECLOCK("ZCQ",.F.)
                    ZCQ->ZCQ_STATUS := "2"
                    ZCQ->ZCQ_MSG    := "Integração realizada con sucesso."
                    ZCQ->ZCQ_CODE   := "200"
                MSUNLOCK()                   
            ENDIF 
        ENDIF
    ENDIF

    Freeobj(oObj)

endif

(cTab)->(dbCloseArea())	
   

Return
/*/{Protheus.doc} CJBK09API
Rotina de integração via REST
@author carlos.henrique
@since 01/01/2015
@version undefined
@param aBlocoMsg, array, descricao
@type function
/*/
Static Function CJBK09API()
Local cTab   := GetNextAlias()
Local oRest  := Nil
Local aHeader:= {}
Local oRet	 := nil
Local cToken := ""
Local nStatus := 0

DbSelectArea("ZCT")
ZCT->(DbSetOrder(01))
ZCT->(DbGoTop())
cToken := AllTrim(ZCT->ZCT_TOKEN)

BeginSql Alias cTab
    SELECT ZCP_TIPO
            ,LTRIM(RTRIM(ZCP_URLCAL)) AS ZCP_URLCAL
            ,LTRIM(RTRIM(ZCP_PTOKEN)) AS ZCP_PTOKEN
            ,LTRIM(RTRIM(ZCP_USRCAL)) AS ZCP_USRCAL
            ,LTRIM(RTRIM(ZCP_PSWCAL)) AS ZCP_PSWCAL
            ,LTRIM(RTRIM(ZCP_PENVIO)) AS ZCP_PENVIO
    FROM %TABLE:ZCP% ZCP 
    WHERE ZCP_FILIAL=%xfilial:ZCP%
        AND ZCP_TIPO='1'
        AND ZCP_TIPRMQ='2'  
        AND ZCP_STATUS='1' 
        AND ZCP_FILA=%Exp:ZCQ->ZCQ_FILA% 
        AND ZCP.D_E_L_E_T_ =''
    ORDER BY ZCP_ORDEM    		
EndSql

//aRet:= GETLastQuery()[2]
IF (cTab)->(!EOF()) 

    oRest := FWRest():New(ALLTRIM((cTab)->ZCP_URLCAL))        

    Aadd(aHeader,'Content-Type: application/json;charset=utf-8')
    Aadd(aHeader,'Accept: application/json')    
    aAdd(aHeader,'Authorization: Bearer ' + cToken )
    
    IF ALLTRIM(ZCQ->ZCQ_TIPENV) == "RETORNO_PAGAMENTO_BOLSA"
        oRest:setPath( ALLTRIM((cTab)->ZCP_PENVIO) + ALLTRIM(ZCQ->ZCQ_IDENTI) )
    ELSEIF ALLTRIM(ZCQ->ZCQ_TIPENV) == "RETORNO_FATURAMENTO"
        oRest:setPath( ALLTRIM((cTab)->ZCP_PENVIO))       
    ELSE
        oRest:setPath(ALLTRIM((cTab)->ZCP_PENVIO))
    ENDIF
    

    IF ZCQ->ZCQ_OPEENV == "1"
        oRest:SetPostParams(ZCQ->ZCQ_JSON)
        oRest:Post(aHeader)
    ELSEIF ZCQ->ZCQ_OPEENV == "2"
        oRest:Put(aHeader,ZCQ->ZCQ_JSON)
    ELSEIF ZCQ->ZCQ_OPEENV == "3"    
        oRest:Delete(aHeader,ZCQ->ZCQ_JSON)
    ENDIF
    
    nStatus := HTTPGetStatus()

    IF !Empty(oRest:CINTERNALERROR)
        
        RECLOCK("ZCQ",.F.)
            ZCQ->ZCQ_STATUS := "1"
            ZCQ->ZCQ_MSG    := oRest:CINTERNALERROR
        MSUNLOCK()      

    ELSEIF nStatus >= 200 .And. nStatus <= 299
        
        RECLOCK("ZCQ",.F.)  
            ZCQ->ZCQ_STATUS := "2"
            ZCQ->ZCQ_CODE   := "200"   
            ZCQ->ZCQ_MSG    := "Integração realizada com sucesso"
        MSUNLOCK()   

    ELSE
        oRet:= JsonObject():new()
        oRet:fromJSON( oRest:GetResult() )

		if !Empty(oRet:GetJsonText("httpStatusCode"))

            RECLOCK("ZCQ",.F.)
                ZCQ->ZCQ_STATUS := "1"
                ZCQ->ZCQ_MSG    := "Código " + AllTrim(oRet:GetJsonText("httpStatusCode")) + " - " + AllTrim(oRet:GetJsonText("message"))
                ZCQ->ZCQ_CODE   := AllTrim(oRet:GetJsonText("httpStatusCode")) 
            MSUNLOCK()  

			 
		elseif !Empty(oRest:GetResult())
            
            IF !Empty(oRet:GetJsonText("httpStatusCode"))
                RECLOCK("ZCQ",.F.)
                    ZCQ->ZCQ_STATUS := "1"
                    ZCQ->ZCQ_MSG    := "Código " + AllTrim(oRet:GetJsonText("httpStatusCode")) + " - " + AllTrim(oRet:GetJsonText("message"))
                    ZCQ->ZCQ_CODE   := AllTrim(oRet:GetJsonText("httpStatusCode")) 
                MSUNLOCK()  
            ELSE   
                RECLOCK("ZCQ",.F.)
                    ZCQ->ZCQ_STATUS := "1"
                    ZCQ->ZCQ_MSG    := AllTrim(oRest:GetResult())
                    ZCQ->ZCQ_CODE   := cValtoChar(nStatus)
                MSUNLOCK()               
            ENDIF
		else
            RECLOCK("ZCQ",.F.)
                ZCQ->ZCQ_STATUS := "1"
                ZCQ->ZCQ_MSG    := AllTrim(oRest:GetResult())
                ZCQ->ZCQ_CODE   := cValtoChar(nStatus)
            MSUNLOCK()  
		endif

        FreeObj(oRet)

    endif  

    FreeObj(oRest)
endif

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
Local aParam := {"P","CJOBK09","",{},""}    
Return aParam

/*/{Protheus.doc} CJBK09RESP
Função que processa o envio das respostas para o Kairós
@author danilo.grodzicki
@since 04/09/2020
@version undefined
@type function
/*/
STATIC FUNCTION CJBK09RESP(lJob)

Local cZCP  := GetNextAlias()
Local cZCQ  := ""
Local nX    := 0
Local aFila := {}

BeginSql Alias cZCP
	SELECT * FROM %TABLE:ZCP% ZCP 
	WHERE ZCP_FILIAL=%xfilial:ZCP%
		AND ZCP_TIPO='1'
		AND ZCP_TIPRMQ='1'  
		AND ZCP_STATUS='1' 
		AND ZCP.D_E_L_E_T_ =''
	ORDER BY ZCP_ORDEM    		
EndSql

//aRet:= GETLastQuery()[2]

IF (cZCP)->(!EOF()) 

	WHILE (cZCP)->(!EOF())		
		
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBK09RESP] INICIO FILA:" + TRIM((cZCP)->ZCP_FILA))
   
		cZCQ:= GetNextAlias()
		BeginSql Alias cZCQ
			SELECT R_E_C_N_O_ AS RECZCQ 
			FROM %TABLE:ZCQ% ZCQ 
			WHERE ZCQ_FILIAL = %xfilial:ZCQ% 
		  		AND ZCQ_STATUS <> '0'
				AND ZCQ_RETORN <> 'S'
				AND ZCQ_FILA = %Exp:(cZCP)->ZCP_FILA% 
				AND ZCQ.D_E_L_E_T_ = ''    
		EndSql   

		//aRet:= GETLastQuery()[2]
		WHILE (cZCQ)->(!EOF())	 
			AADD(aFila,(cZCQ)->RECZCQ)                        
			(cZCQ)->(dbSkip())	
		END  
		
		(cZCQ)->(dbCloseArea())    

		IF !EMPTY(aFila)

			//Processamento em grid
			IF (cZCP)->ZCP_GRID == "1" 
				
				oGrid := GridClient():New()
				
                lRet := oGrid:BatchExec("U_CJBK09AMB",{cEmpAnt,cFilAnt,""},"U_CJBK09RF",aFila)

				If !lRet .and. Empty(oGrid:aGridThreads)
					CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBK09RESP] Nenhum Agente do GRID disponivel no Momento.")
				EndIf

				If !empty(oGrid:aErrorProc)               
					varinfo('Lista de Erro',oGrid:aErrorProc)   
				Endif   

				If !empty(oGrid:aSendProc)                 
					varinfo('Não processado',oGrid:aSendProc)   
				Endif 
			else

				For nX:= 1 to len(aFila)
					U_CJBK09RF(aFila[nX])
				Next	
			endif		
		else
			CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBK09RESP] Nenhuma fila pendente de envio")
		endif        

		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBK09RESP] FIM FILA:" + TRIM((cZCP)->ZCP_FILA))              

		(cZCP)->(dbSkip())	
	END  
ENDIF    

(cZCP)->(dbCloseArea())	

Return

/*/{Protheus.doc} CJBK09RF
Rotina de retono das fila para o Kairós
@author danilo.grodzicki
@since 04/09/2020
@version undefined
@type function
/*/
User Function CJBK09RF(nRecno)

//Local cMsg
Local cEncode64

Local oObj     := nil
Local lLockZCS := .F.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBK09RF] Inicio envio RECNO:" + CVALTOCHAR(nRecno) )

dbselectarea("ZCQ")
ZCQ->(dbGoto(nRecno))	

IF ZCQ->(!EOF())

	DBSelectArea("ZCP")
	ZCP->(DBSetOrder(01))
	ZCP->(DbSeek(xFilial("ZCP")+ZCQ->ZCQ_FILA))

	oObj:= Rabbit():New(AllTrim(ZCP->ZCP_URLRMQ),;
						AllTrim(ZCP->ZCP_TCPRMQ),;
						AllTrim(ZCP->ZCP_USRRMQ),;
						AllTrim(ZCP->ZCP_PSWRMQ))

	IF !EMPTY(oObj:Error())

		IF lJob
			CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJBK09RF] " + oObj:Error())
		ELSE
			MSGALERT( oObj:Error() )
		ENDIF

	else

        oObj:setFila( AllTrim(ZCP->ZCP_TIPO),; 
                      AllTrim(ZCP->ZCP_FILRET))

		IF !EMPTY(oObj:Error())
			
			IF lJob
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJBK09RF] " + oObj:Error())
			ELSE
				MSGALERT( oObj:Error() )
			ENDIF

		else

//			cMsg := AllTrim(ZCQ->ZCQ_MSG)
//			cMsg := StrTran(cMsg,'"','')
//			cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
//			cMsg := StrTran(cMsg,Chr(10)," ")
//			cMsg := StrTran(cMsg,"\","")
			
			cEncode64 := Encode64(AllTrim(ZCQ->ZCQ_MSG))

			oObj:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
							'"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
							'"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
							'"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
							'"resposta": {'+;
							'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
							'"Message": "' + cEncode64 +'"}'+;
						'}')

			IF !EMPTY(oObj:Error())

				IF lJob
					CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5)+"][CJBK09RF] " + oObj:Error())
				ELSE
					MSGALERT( oObj:Error() )
				ENDIF

			ELSE

				RECLOCK("ZCQ",.F.)
					ZCQ->ZCQ_RETORN := "S"
				MSUNLOCK()                   
				
				// Gera movimento na fila DW3
				if ZCP->ZCP_ENVDW3 == "1" .and. ZCQ->ZCQ_STATUS == "2"
					dbselectarea("ZCS")
					ZCS->(dbsetorder(1))
					lLockZCS:= !ZCS->(dbSeek(xFilial("ZCS") + ZCQ->ZCQ_IDLOG))
					RECLOCK("ZCS",lLockZCS)
						ZCS->ZCS_FILIAL:= ZCQ->ZCQ_FILIAL
						ZCS->ZCS_TIPENV:= ZCQ->ZCQ_TIPENV
						ZCS->ZCS_OPEENV:= ZCQ->ZCQ_OPEENV
						ZCS->ZCS_IDENTI:= ZCQ->ZCQ_IDENTI
						ZCS->ZCS_URL   := ZCQ->ZCQ_URL
						ZCS->ZCS_IDLOG := ZCQ->ZCQ_IDLOG
						ZCS->ZCS_DTINTE:= ZCQ->ZCQ_DTINTE
						ZCS->ZCS_HRINTE:= ZCQ->ZCQ_HRINTE
						ZCS->ZCS_STATUS:= "0"
						ZCS->ZCS_FILA  := ZCP->ZCP_FILDW3
						ZCS->ZCS_CODE  := "" //ZCQ->ZCQ_CODE
						ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
					MSUNLOCK()
				endif

			ENDIF 
		endif
	ENDIF

	Freeobj(oObj)
	
ENDIF

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJBK09RF] Fim envio RECNO:" + CVALTOCHAR(nRecno) )

Return
