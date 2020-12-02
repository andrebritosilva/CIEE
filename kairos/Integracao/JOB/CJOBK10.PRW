#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK10
JOB de processamento de envio das filas para DW3
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
User function CJOBK10()
Local lJob		:= GetRemoteType() == -1 // Verifica se é job
Local cEmpInt	:= CEMPANT
Local cFilInt	:= CFILANT
Local nOpca		:= 0

IF !lJob	
	IF MSGYESNO("Confirma o processamento de envio das filas para DW3 ?")
		nOpca:= 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Iniciando processamento via schedule.")
	nOpca:= 1		                                                                                                          
ENDIF

IF !LockByName("CJOBK10",.T.,.T.)
	nOpca:= 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK10PR(lJob) },,"Realizando processamento de envio das filas para DW3, aguarde...")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Processo Iniciado para "+cEmpInt+"-"+cFilInt)
		CJBK10PR(lJob) 
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Processo Finalizado para "+cEmpInt+"-"+cFilInt)	
	ENDIF
	
	UnLockByName("CJOBK10",.T.,.T.)	
	
ENDIF

RETURN 
/*/{Protheus.doc} CJBK10PR
Rotina de processamento de envio das filas para DW3
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK10PR(lJob)
Local cZCP  := GetNextAlias()
Local cZCS  := ""
Local nX    := 0
Local aFila := {}

BeginSql Alias cZCP
    SELECT * FROM %TABLE:ZCP% ZCP 
    WHERE ZCP_FILIAL=%xfilial:ZCP%
        AND ZCP_TIPO='2'
        AND ZCP_TIPRMQ='2'  
        AND ZCP_STATUS='1' 
        AND ZCP.D_E_L_E_T_ =''
    ORDER BY ZCP_ORDEM    		
EndSql

//aRet:= GETLastQuery()[2]
IF (cZCP)->(!EOF()) 

    WHILE (cZCP)->(!EOF())		
        
        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] INICIO FILA:" + TRIM((cZCP)->ZCP_FILA))
		
        cZCS:= GetNextAlias()
        BeginSql Alias cZCS
            SELECT R_E_C_N_O_ AS RECZCS FROM %TABLE:ZCS% ZCS 
            WHERE ZCS_FILIAL=%xfilial:ZCS% 
                AND ZCS_STATUS IN ('0','1')
    			AND ZCS_QTDTEN <= %Exp:GetMv("CI_QTDTENT")%
                AND ZCS_FILA=%Exp:(cZCP)->ZCP_FILA% 
                AND ZCS.D_E_L_E_T_ =''    
        EndSql   

        //aRet:= GETLastQuery()[2]
        WHILE (cZCS)->(!EOF())	 
            AADD(aFila,(cZCS)->RECZCS)                        
        (cZCS)->(dbSkip())	
        END  
        
        (cZCS)->(dbCloseArea())    

        IF !EMPTY(aFila)
            
            //Processamento em grid
            IF (cZCP)->ZCP_GRID == "1" 
                
                oGrid := GridClient():New()
                
                lRet := oGrid:BatchExec("U_CJBK10AMB",{cEmpAnt,cFilAnt,""},"U_CJBK10RET",aFila)

                If !lRet .and. Empty(oGrid:aGridThreads)
                    CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Nenhum Agente do GRID disponivel no Momento.")
                EndIf

                If !empty(oGrid:aErrorProc)               
                    varinfo('Lista de Erro',oGrid:aErrorProc)   
                Endif   

                If !empty(oGrid:aSendProc)                 
                    varinfo('Não processado',oGrid:aSendProc)   
                Endif 
            else
                For nX:= 1 to len(aFila)
                    U_CJBK10AMB({cEmpAnt,cFilAnt,"U_CJBK10RET("+CVALTOCHAR(aFila[nX])+")"})
                Next	
            endif		
        else
            CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Nenhuma fila pendente de envio")
        endif        

        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] FIM FILA:" + TRIM((cZCP)->ZCP_FILA))              

    (cZCP)->(dbSkip())	
    END  
ELSE

ENDIF    

(cZCP)->(dbCloseArea())	

Return
/*/{Protheus.doc} CJBK10AMB
Prepara ambiente GRID
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
USER Function CJBK10AMB(aParms)
Local cEmpParm:= aParms[1]	// Empresa --> cEmpAnt
Local cFilParm:= aParms[2]	// Filial  --> cFilAnt
Local cFunExec:= aParms[3]	// Rotina  ---> Apenas startjob

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Preparando ambiente")

RpcSetType(3)
RPCSetEnv(cEmpParm,cFilParm) 

IF !EMPTY(cFunExec)
	&(cFunExec)
ENDIF

Return .T.
/*/{Protheus.doc} CJBK10RET
Rotina de retono das fila
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
User Function CJBK10RET(nRecno)
Local cTEnvDW3:= AllTrim(SuperGetMV("CI_TENVDW3",,"2")) //Define o tipo de integração DW3 => 1=Fila;2=Rest

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Inicio envio RECNO:" + CVALTOCHAR(nRecno) )

dbselectarea("ZCS")
ZCS->(dbGoto(nRecno))	
IF ZCS->(!EOF())

    //Envio via FILA RABBITMQ
    IF cTEnvDW3 == "1"

        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Processando via RabbitMQ.")
        CJBK10RMQ()
    
    //Envio via REST
    ELSEIF cTEnvDW3 == "2"

        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Processando via rest.")
        CJBK10API()
    
    ELSE
        CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Tipo de envio DW3 invalido:" + cTEnvDW3)
    ENDIF      

ENDIF

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Fim envio RECNO:" + CVALTOCHAR(nRecno) )

Return
/*/{Protheus.doc} CJBK10RMQ
Rotina de integração via RabbitMQ
@author carlos.henrique
@since 01/01/2015
@version undefined
@param aBlocoMsg, array, descricao
@type function
/*/
Static Function CJBK10RMQ()
Local cTab:= GetNextAlias()
Local oObj:= nil
Local cVerbo:= ""

BeginSql Alias cTab
    SELECT * FROM %TABLE:ZCP% ZCP  
    WHERE ZCP_FILIAL=%xfilial:ZCP%
        AND ZCP_TIPO='2'
        AND ZCP_TIPRMQ='2'  
        AND ZCP_STATUS='1' 
        AND ZCP_FILA=%Exp:ZCS->ZCS_FILA% 
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

        RECLOCK("ZCS",.F.)
            ZCS->ZCS_STATUS := "2"
            ZCS->ZCS_MSG    := oObj:Error()
        MSUNLOCK()    
    ELSE                                    

        oObj:setFila( (cTab)->ZCP_TIPO,; 
                        (cTab)->ZCP_FILA)

        IF !EMPTY(oObj:Error())            
            RECLOCK("ZCS",.F.)
                ZCS->ZCS_STATUS := "2"
                ZCS->ZCS_MSG    := oObj:Error()
            MSUNLOCK()    
        ELSE

            CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] Processando via Rabbit.")

            IF ZCS->ZCS_OPEENV == "1"
                cVerbo:="POST"
            ELSEIF ZCS->ZCS_OPEENV == "2"
                cVerbo:="PUT"
            ELSEIF ZCS->ZCS_OPEENV == "3"    
                cVerbo:="DELETE"
            ENDIF

            oObj:Sender('{"tipoEnvio":"'+ TRIM(ZCS->ZCS_TIPENV)  +'",'+;
                        '"operacaoEnvio":' + cVerbo +','+;
                        '"idEntidade":' + TRIM(ZCS->ZCS_IDENTI) +','+;
                        '"url":"/fila/dw3/' + TRIM(ZCS->ZCS_IDLOG) +'",'+;  //TODO-Desenvolver método get para consulta da fila DW3
                        '"idLog":' + TRIM(ZCS->ZCS_IDLOG)+'}')  

            IF !EMPTY(oObj:Error())
                RECLOCK("ZCS",.F.)
                    ZCS->ZCS_STATUS := "2"
                    ZCS->ZCS_MSG    := oObj:Error()
                MSUNLOCK()                     
            ELSE
                RECLOCK("ZCS",.F.)
                    ZCS->ZCS_STATUS := "2"
                    ZCS->ZCS_MSG    := "Integração realizada con sucesso."
                    ZCS->ZCS_CODE   := "200"
                MSUNLOCK()                   
            ENDIF 
        ENDIF
    ENDIF

    Freeobj(oObj)

endif

(cTab)->(dbCloseArea())	
   

Return
/*/{Protheus.doc} CJBK10API
Rotina de integração via REST
@author carlos.henrique
@since 01/01/2015
@version undefined
@param aBlocoMsg, array, descricao
@type function
/*/
Static Function CJBK10API()
Local cTab   := GetNextAlias()
Local oRest  := Nil
Local aHeader:= {}
Local oRet	 := nil
Local cToken := ""

BeginSql Alias cTab
    SELECT ZCP_TIPO
            ,LTRIM(RTRIM(ZCP_URLCAL)) AS ZCP_URLCAL
            ,LTRIM(RTRIM(ZCP_PTOKEN)) AS ZCP_PTOKEN
            ,LTRIM(RTRIM(ZCP_USRCAL)) AS ZCP_USRCAL
            ,LTRIM(RTRIM(ZCP_PSWCAL)) AS ZCP_PSWCAL
            ,LTRIM(RTRIM(ZCP_PENVIO)) AS ZCP_PENVIO
    FROM %TABLE:ZCP% ZCP 
    WHERE ZCP_FILIAL=%xfilial:ZCP%
        AND ZCP_TIPO='2'
        AND ZCP_TIPRMQ='2'  
        AND ZCP_STATUS='1' 
        AND ZCP_FILA=%Exp:ZCS->ZCS_FILA% 
        AND ZCP.D_E_L_E_T_ =''
    ORDER BY ZCP_ORDEM    		
EndSql

//aRet:= GETLastQuery()[2]
IF (cTab)->(!EOF()) 

    oRest := FWRest():New(ALLTRIM((cTab)->ZCP_URLCAL))        

    Aadd(aHeader,'Content-Type: application/json;charset=utf-8')
    Aadd(aHeader,'Accept: application/json')    

    IF !EMPTY((cTab)->ZCP_PTOKEN)
        CJBK10GT((cTab)->ZCP_TIPO,(cTab)->ZCP_URLCAL,(cTab)->ZCP_PTOKEN,(cTab)->ZCP_USRCAL,(cTab)->ZCP_PSWCAL,@cToken)
        aAdd(aHeader, 'Authorization: Bearer ' + cToken )
    ENDIF    

    oRest:setPath(ALLTRIM((cTab)->ZCP_PENVIO))

    IF ZCS->ZCS_OPEENV == "1"
        oRest:SetPostParams(ZCS->ZCS_JSON)
        oRest:Post(aHeader)
    ELSEIF ZCS->ZCS_OPEENV == "2"
        oRest:Put(aHeader,ZCS->ZCS_JSON)
    ELSEIF ZCS->ZCS_OPEENV == "3"    
        oRest:Delete(aHeader,ZCS->ZCS_JSON)
    ENDIF
    
    IF !Empty(oRest:CINTERNALERROR)
        
        RECLOCK("ZCS",.F.)
            ZCS->ZCS_STATUS := "1"
            ZCS->ZCS_MSG    := oRest:CINTERNALERROR
			ZCS->ZCS_QTDTEN := ZCS->ZCS_QTDTEN + 1
        MSUNLOCK()      

    ELSEIF oRest:GetHTTPCode() == "200" .or. oRest:GetHTTPCode() == "201"
        
        RECLOCK("ZCS",.F.)
            ZCS->ZCS_STATUS := "2"
            ZCS->ZCS_CODE   := "200"   
            ZCS->ZCS_MSG    := "PROCESSADO"
        MSUNLOCK()   

    ELSE
        oRet:= JsonObject():new()
        oRet:fromJSON( oRest:GetResult() )

		if !Empty(oRet:GetJsonText("status"))

            RECLOCK("ZCS",.F.)
                ZCS->ZCS_STATUS := "1"
                ZCS->ZCS_MSG    := "Código " + AllTrim(oRest:GetHTTPCode()) + " - " + AllTrim(oRet:GetJsonText("status")) + " - " + AllTrim(oRet:GetJsonText("message"))
                ZCS->ZCS_CODE   := AllTrim(oRet:GetJsonText("status"))
 				ZCS->ZCS_QTDTEN := ZCS->ZCS_QTDTEN + 1
           MSUNLOCK()  

			 
		elseif !Empty(oRest:GetResult())
            
            IF !EMPTY(oRest:GetHTTPCode())
                RECLOCK("ZCS",.F.)
                    ZCS->ZCS_STATUS := "1"
                    ZCS->ZCS_MSG    := "Código " + AllTrim(oRest:GetHTTPCode()) + " - " + AllTrim(oRest:GetResult())
                    ZCS->ZCS_CODE   := AllTrim(oRet:GetJsonText("status")) 
					ZCS->ZCS_QTDTEN := ZCS->ZCS_QTDTEN + 1
                MSUNLOCK()  
            ELSE   
                RECLOCK("ZCS",.F.)
                    ZCS->ZCS_STATUS := "1"
                    ZCS->ZCS_MSG    := AllTrim(oRest:GetResult())
                    ZCS->ZCS_CODE   := ""
					ZCS->ZCS_QTDTEN := ZCS->ZCS_QTDTEN + 1
                MSUNLOCK()               
            ENDIF
		else
            RECLOCK("ZCS",.F.)
                ZCS->ZCS_STATUS := "1"
                ZCS->ZCS_MSG    := "ERRO INTEGRAÇÃO - Código " + AllTrim(oRest:GetHTTPCode())
                ZCS->ZCS_CODE   := AllTrim(oRet:GetJsonText("status"))
				ZCS->ZCS_QTDTEN := ZCS->ZCS_QTDTEN + 1
            MSUNLOCK()  
		endif

        FreeObj(oRet)

    endif  

    FreeObj(oRest)
endif

(cTab)->(dbCloseArea())	

Return

/*/{Protheus.doc} CJBK10GT
Método para pegar o token
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
Static function CJBK10GT(cTpFila,cUrl,cPToken,cUser,cPsw,cToken)
Local oRest  := Nil
Local aHeader:= {}
Local cJSON  := ""
Local oRet	 := nil
Local lRet   := .T.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] INICIO TOKEN")

cJSON+= '{'
cJSON+= '   "username": "' + cUser + '",'
cJSON+= '   "password": "' + cPsw + '"'
cJSON+= '}'  

aAdd(aHeader, 'Content-Type: application/json' )
aAdd(aHeader, 'Accept: application/json'       )

oRest:= FWRest():New(cUrl)
oRest:setPath(cPToken)
oRest:SetPostParams(cJSON)

If oRest:Post(aHeader)
	
    oRet:= JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )
	cToken = oRet["token"]
	FreeObj(oRet)

ELSE
	lRet:= .F.
    oRet:= JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )

    RECLOCK("ZCS",.F.)
        ZCS->ZCS_STATUS := "1"
        ZCS->ZCS_MSG    := oRet:GetJsonText("message")
        ZCS->ZCS_CODE   := oRet:GetJsonText("status") 
        ZCS->ZCS_JSON   := oRet:toJson()              
		ZCS->ZCS_QTDTEN := ZCS->ZCS_QTDTEN + 1
   MSUNLOCK()    

    FreeObj(oRet)

Endif

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK10] FIM TOKEN")

Return lRet


/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
Static Function Scheddef()
Local aParam := {"P","CJOBK10","",{},""}    
Return aParam
