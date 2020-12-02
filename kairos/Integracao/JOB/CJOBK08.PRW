#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CJOBK08
JOB de processamento das filas DW3
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
User function CJOBK08()
Local lJob		:= GetRemoteType() == -1 // Verifica se é job
Local cEmpInt	:= CEMPANT
Local cFilInt	:= CFILANT
Local nOpca		:= 0

IF !lJob	
	IF MSGYESNO("Confirma o processamento da Fila DW3 ?")
		nOpca:= 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK08] Iniciando processamento via schedule.")
	nOpca:= 1		                                                                                                          
ENDIF

IF !LockByName("CJOBK08",.T.,.T.)
	nOpca:= 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK08] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK07PR(lJob) },,"Realizando processamento da Fila DW3, aguarde...")
	ELSE
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK08] Processo Iniciado para "+cEmpInt+"-"+cFilInt)
		CJBK07PR(lJob) 
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK08] Processo Finalizado para "+cEmpInt+"-"+cFilInt)	
	ENDIF
	
	UnLockByName("CJOBK08",.T.,.T.)	
	
ENDIF

RETURN 
/*/{Protheus.doc} CJBK07PR
Rotina de processamento da Fila DW3
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
STATIC FUNCTION CJBK07PR(lJob)
Local cTab  := GetNextAlias()
Local oObj  := nil
Local nCnt  := 0

BeginSql Alias cTab
    SELECT * FROM %TABLE:ZCP% ZCP 
    WHERE ZCP_FILIAL=%xfilial:ZCP%
        AND ZCP_TIPO='2'  
        AND ZCP_TIPRMQ='1'
        AND ZCP_STATUS='1'  
        AND ZCP.D_E_L_E_T_ =''
    ORDER BY ZCP_ORDEM    		
EndSql

//aRet:= GETLastQuery()[2]
IF (cTab)->(!EOF()) 

    WHILE (cTab)->(!EOF())		

        oObj:= Rabbit():New((cTab)->ZCP_URLRMQ,;
                            (cTab)->ZCP_TCPRMQ,;
                            (cTab)->ZCP_USRRMQ,;
                            (cTab)->ZCP_PSWRMQ)
        
        oObj:setFila( (cTab)->ZCP_TIPO,; 
                      (cTab)->ZCP_FILA)

        IF EMPTY(oObj:Error())
            For nCnt:= 1 to oObj:MessageCount()
                oObj:Receiver()
            next                       
        ELSE
            CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK08] " + oObj:Error() )
        ENDIF

        //Processa fila
        oObj:Processa((cTab)->ZCP_GRID,;
                      (cTab)->ZCP_FILA,;
                      (cTab)->ZCP_FUNPRO,;
                      (cTab)->ZCP_URLCAL,;
                      (cTab)->ZCP_USRCAL,;
                      (cTab)->ZCP_PSWCAL,;
                      (cTab)->ZCP_PTOKEN,;
                      (cTab)->ZCP_FILRET)                       

        Freeobj(oObj)              
        
    (cTab)->(dbSkip())	
    END  
ELSE

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
Local aParam := {"P","CJOBK08","",{},""}    
Return aParam

/*/{Protheus.doc} TSTFILAD
Rotina de teste
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
user function TSTFILAD()
Local oObj    := nil
Local nCnt    := 0

RpcSetType(3)
IF RPCSetEnv("99","01")  
    //--------------------
    //Gera fila de teste
    //--------------------
    oObj:= Rabbit():New("localhost","5672","guest","guest")

    For nCnt:= 1 to 100
        oObj:setFila("1","dev1-integracao-unidades-ciee-totvs")
        oObj:Sender('{"tipoEnvio":"UNIDADES_CIEE","operacaoEnvio": "POST","idEntidade":' + CVALTOCHAR(nCnt) +',"url":"/unit/unidades-ciee/101","idLog":' + CVALTOCHAR(nCnt) +'}')
    next

    Freeobj(oObj)

ENDIF

RpcClearEnv()

Return
