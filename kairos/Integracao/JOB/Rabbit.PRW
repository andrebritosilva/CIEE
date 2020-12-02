#include 'protheus.ch'
#INCLUDE "TBICONN.CH"

#define AMQP_AUTODELETE .F.
#define AMQP_EXCLUSIVE .F.
#define AMQP_DURABLE .T.
#define AMQP_PERSISTENT .F.
#define AMQP_AUTOACK .F.
#define AMQP_FIXED_CHANNEL_ID 1

/*/{Protheus.doc} Rabbit
Classe de integração com Rabbit
@author carlos.henrique
@since 10/05/2019
@version undefined

@type class
/*/
Class Rabbit FROM tAmqp
	DATA Url
	DATA Usr
	DATA Psw
	DATA PToken
	DATA Fila
	DATA TpFila
	DATA Token
	DATA Path
	Method New(cRMQURL,nRMQTCP,cRMQUSR,cRMQPRW) CONSTRUCTOR
	Method setFila(cTpFila,cFila) 
	Method Sender(cMsg)  //Método para publicar uma mensagem na fila
	Method Receiver()    //Método para consumir uma mensagem na fila
//    Method GetToken()    //Método de consulta do token
//    Method CallBack()    //Método de consulta do payload
	Method Processa(cfnProc,cUrlCal,cUsrCal,cPswCal,cPToken)    //Método de processamento
End Class

/*/{Protheus.doc} New
Inicia objeto tAMQP com um determinado AMQP Server.
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
Method New(cRMQURL,nRMQTCP,cRMQUSR,cRMQPRW) Class Rabbit
:New(TRIM(cRMQURL),VAL(nRMQTCP),TRIM(cRMQUSR),TRIM(cRMQPRW),AMQP_FIXED_CHANNEL_ID)

self:CONSUMETIMEOUT:= 20

Return self

/*/{Protheus.doc} setFila
Método para declarar a fila no Rabbit
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
Method setFila(cTpFila,cFila) Class Rabbit

self:TpFila := cTpFila      //Tipo da fila
Self:Fila   := TRIM(cFila)  //Nome da fila

//Self:BasicQos(0,100,.T.)

Self:QueueDeclare(Self:Fila,AMQP_DURABLE,AMQP_EXCLUSIVE,AMQP_AUTODELETE)

Return .T.

/*/{Protheus.doc} Sender
Método para publicar uma mensagem na fila
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
Method Sender(cMsg) Class Rabbit

Self:BasicPublish("",Self:Fila, AMQP_PERSISTENT, EncodeUTF8(cMsg) )

Return .T.

/*/{Protheus.doc} Receiver
Método para receber a mensagem da fila
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
Method Receiver() Class Rabbit
Local oRet:= JsonObject():new()
Local cVerbo:= ""

Self:BasicConsume(Self:Fila, AMQP_AUTOACK)
oRet:fromJson(Self:Body)

IF self:TpFila == "1"      //Kairos
	
	cVerbo:= UPPER(ALLTRIM(oRet:GetJsonText("operacaoEnvio")))

	RECLOCK("ZCQ",.T.)
		ZCQ->ZCQ_FILIAL := XFILIAL("ZCQ")
		ZCQ->ZCQ_TIPENV := oRet:GetJsonText("tipoEnvio")

		IF cVerbo == "POST" .or. empty(cVerbo)
			ZCQ->ZCQ_OPEENV:= "1"
		ELSEIF cVerbo == "PUT"
			ZCQ->ZCQ_OPEENV:= "2"
		ELSEIF cVerbo == "DELETE"
			ZCQ->ZCQ_OPEENV:= "3"
		ENDIF
		
		ZCQ->ZCQ_IDENTI := oRet:GetJsonText("idEntidade")
		ZCQ->ZCQ_URL    := oRet:GetJsonText("url")
		ZCQ->ZCQ_IDLOG  := oRet:GetJsonText("idLog")
		ZCQ->ZCQ_DTINTE := DATE()
		ZCQ->ZCQ_HRINTE := Time()
		ZCQ->ZCQ_STATUS := "0"
		ZCQ->ZCQ_FILA   := Self:Fila
		ZCQ->ZCQ_RETORN := "N"
		ZCQ->ZCQ_QTDTEN := 0
	MSUNLOCK()
	
	self:Path := ALLTRIM(ZCQ->ZCQ_URL)

ELSEIF self:TpFila == "2"  //DW3

	cVerbo:= UPPER(ALLTRIM(oRet:GetJsonText("tipoEnvio")))

	RECLOCK("ZCS",.T.)
		ZCS->ZCS_FILIAL:= XFILIAL("ZCS")
		ZCS->ZCS_TIPENV:= oRet:GetJsonText("tipoEnvio")
		
		IF cVerbo == "POST" .or. empty(cVerbo)
			ZCQ->ZCQ_TIPENV:= "1"
		ELSEIF cVerbo == "PUT"
			ZCQ->ZCQ_TIPENV:= "2"
		ELSEIF cVerbo == "DELETE"
			ZCQ->ZCQ_TIPENV:= "3"
		ENDIF

		ZCS->ZCS_IDENTI:= oRet:GetJsonText("idEntidade")
		ZCS->ZCS_URL   := oRet:GetJsonText("url")
		ZCS->ZCS_IDLOG := oRet:GetJsonText("idLog")
		ZCS->ZCS_DTINTE:= DATE()
		ZCS->ZCS_HRINTE:= Time()        
		ZCS->ZCS_STATUS:= "0"
		ZCS->ZCS_FILA  := Self:Fila
	MSUNLOCK()
	
	self:Path := ALLTRIM(ZCQ->ZCQ_URL)

ENDIF

Freeobj(oRet)

Return

/*/{Protheus.doc} GetToken
Método para pegar o token
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
/*Method GetToken() Class Rabbit
Local oRest  := Nil
Local aHeader:= {}
Local cJSON  := ""
Local oRet	 := nil
Local lRet   := .T.

cJSON+= '{'
cJSON+= '   "username": "' + self:Usr + '",'
cJSON+= '   "password": "' + self:Psw + '"'
cJSON+= '}'  

aAdd(aHeader, 'Content-Type: application/json' )
aAdd(aHeader, 'Accept: application/json'       )

oRest:= FWRest():New(self:Url)
oRest:setPath(self:PToken)
oRest:SetPostParams(cJSON)

If oRest:Post(aHeader)
	
	oRet:= JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )
	self:Token = oRet["token"]
	FreeObj(oRet)

ELSE
	lRet:= .F.
	oRet:= JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )
	
	IF self:TpFila == "1"      //Kairos

		RECLOCK("ZCQ",.F.)
			ZCQ->ZCQ_STATUS := "1"
			ZCQ->ZCQ_MSG    := oRet:GetJsonText("message") 
			ZCQ->ZCQ_MSG    := iif(Empty(oRet:GetJsonText("message")),"Erro na integração, por favor, enfileirar novamente.",oRet:GetJsonText("message"))
			ZCQ->ZCQ_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
			ZCQ->ZCQ_JSON   := oRet:toJson()              
		MSUNLOCK()    

	ELSEIF self:TpFila == "2"  //DW3

		RECLOCK("ZCQ",.F.)
			ZCS->ZCS_STATUS := "1"
			ZCS->ZCS_MSG    := oRet:GetJsonText("message")
			ZCS->ZCS_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
			ZCS->ZCS_JSON   := oRet:toJson()              
		MSUNLOCK()    

	endif

	FreeObj(oRet)

Endif

Return lRet*/

/*/{Protheus.doc} CallBack
Método para pegar a mensagem da fila do kairos
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
/*Method CallBack() Class Rabbit
Local oRest  := Nil
Local aHeader:= {}
Local lRet   := .T.
Local oRet	 := nil

IF self:GetToken()

	oRest := FWRest():New(self:Url)

	aAdd(aHeader, 'Content-Type: application/json' )
	aAdd(aHeader, 'Authorization: Bearer ' + self:Token )

	IF self:TpFila == "1"      //Kairos
		oRest:setPath( ALLTRIM(ZCQ->ZCQ_URL) )
	ELSEIF self:TpFila == "2"      //DW3
		oRest:setPath( ALLTRIM(ZCS->ZCS_URL) )
	endif

	oRet:= JsonObject():new()

	If oRest:GET(aHeader)  
		oRet:fromJSON( oRest:GetResult() )
	else    
		oRet:fromJSON( oRest:GetResult() )
		lRet   := .F.
	Endif

	IF self:TpFila == "1"      //Kairos

		RECLOCK("ZCQ",.F.)
			if oRest:GetHTTPCode()  == "200"
				ZCQ->ZCQ_CODE   := "200"
				ZCQ->ZCQ_JSON   := oRest:GetResult()                                              
			else
				ZCQ->ZCQ_STATUS := "1"
				ZCQ->ZCQ_MSG    := iif(Empty(oRet:GetJsonText("message")),"Erro na integração, por favor, enfileirar novamente.",oRet:GetJsonText("message"))
				ZCQ->ZCQ_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
				ZCQ->ZCQ_JSON   := oRet:toJson()            
			ENDIF    
		MSUNLOCK()    

	ELSEIF self:TpFila == "2"  //DW3

		RECLOCK("ZCQ",.F.)
			if oRest:GetHTTPCode()  == "200"
				ZCS->ZCS_CODE   := "200"
				ZCS->ZCS_JSON   := oRest:GetResult()             
			Else
				ZCS->ZCS_STATUS := "1"
				ZCS->ZCS_MSG    := oRet:GetJsonText("message")
				ZCS->ZCS_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
				ZCS->ZCS_JSON   := oRet:toJson()                                                          
			ENDIF  
		MSUNLOCK()    

	endif

	FreeObj(oRet)
	FreeObj(oRest)
endif

Return lRet*/

/*/{Protheus.doc} Processa
Método de processamento
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
Method Processa(cGrid,cFilPro,cfnProc,cUrlCal,cUsrCal,cPswCal,cPToken,cFilaRet,cEnvDW3,cFilaDW3,cTipoFila) Class Rabbit

Local cMsg, cIdenti
Local oGrid,cTab,nX
Local aFila:= {}
Local aFila2:= {}
//Local lLockZCS:= .F.
default cEnvDW3:= ""
default cFilaDW3:= ""

cfnProc     := TRIM(cfnProc)
self:Url    := TRIM(cUrlCal)   // URL CallBack
self:Usr    := TRIM(cUsrCal)   // Usuário CallBack
self:Psw    := TRIM(cPswCal)   // Senha CallBack
self:PToken := TRIM(cPToken)   // Token CallBack
cFilaRet    := TRIM(cFilaRet)

//Seta Fila de retorno
Self:setFila(cTipoFila,;
			 cFilaRet)

IF cTipoFila == "1"  // Kairos
	
	// Realiza o callback para pegar o JSON
	dbselectarea("ZCQ")

	cTab:= GetNextAlias()

	BeginSql Alias cTab
		SELECT R_E_C_N_O_ AS RECZCQ
		FROM %TABLE:ZCQ% ZCQ
		WHERE ZCQ_FILIAL = %xfilial:ZCQ%
		  AND ZCQ_STATUS = '0'
		  AND ZCQ_FILA = %Exp:cFilPro%
		  AND ZCQ_CODE = ''
		  AND ZCQ.D_E_L_E_T_ = ''
	EndSql
	
	//aRet:= GETLastQuery()[2]

	aFila := {}
	(cTab)->(DbGoTop())
	WHILE (cTab)->(!EOF())
		AADD(aFila,(cTab)->RECZCQ)
		(cTab)->(dbSkip())
	END
	(cTab)->(dbCloseArea())

	// Processamento em grid
	IF cGrid == "1"

		if Len(aFila) > 0

			oGrid := GridClient():New()
			
			lRet := oGrid:BatchExec("U_CRMQAMB",{cEmpAnt,cFilAnt},"U_CALLBACK",aFila)

			If !lRet .and. Empty(oGrid:aGridThreads)
				CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][Rabbit] Nenhum Agente do GRID disponivel no Momento")
			EndIf

			If !empty(oGrid:aErrorProc)
				varinfo('Lista de Erro',oGrid:aErrorProc)
			Endif

			If !empty(oGrid:aSendProc)
				varinfo('Não processado',oGrid:aSendProc)
			Endif
/*
			for nX = 1 to Len(aFila)

				ZCQ->(dbgoto(aFila[nX]))

				if ZCQ->ZCQ_STATUS == "1"

					cMsg := AllTrim(ZCQ->ZCQ_MSG)
					cMsg := StrTran(cMsg,'"','')
					cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
					cMsg := StrTran(cMsg,Chr(10)," ")
					
					Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
									'"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
									'"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
									'"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
									'"resposta": {'+;
									'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
									'"Message": "' + cMsg +'"}'+;
								'}')
				endif

			next
*/
		endif

	else
		
		For nX:= 1 to len(aFila)
			
			IF !U_CALLBACK(aFila[nX])
/*
				cMsg := AllTrim(ZCQ->ZCQ_MSG)
				cMsg := StrTran(cMsg,'"','')
				cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
				cMsg := StrTran(cMsg,Chr(10)," ")

				Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
								'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
								'"Message": "' + cMsg +'"}'+;
							'}')
*/
			ENDIF

		next
	
	endif

	// Pega RECNO para processamento
	cTab:= GetNextAlias()

	BeginSql Alias cTab
		SELECT R_E_C_N_O_ AS RECZCQ,
			   ZCQ_IDENTI
		FROM %TABLE:ZCQ% ZCQ
		WHERE ZCQ_FILIAL = %xfilial:ZCQ%
		  AND ZCQ_STATUS = '0'
		  AND ZCQ_FILA = %Exp:cFilPro%
		  AND ZCQ_CODE = '200'
		  AND ZCQ.D_E_L_E_T_ = ''
		ORDER BY ZCQ_IDENTI, RECZCQ
	EndSql

	//aRet:= GETLastQuery()[2]

	aFila  := {}
	aFila2 := {}
	
	// Processamento em grid
	IF cGrid == "1"
		cIdenti := space(15)
		(cTab)->(DbGoTop())
		WHILE (cTab)->(!EOF())
			if AllTrim(cIdenti) <> AllTrim((cTab)->ZCQ_IDENTI)
				AADD(aFila,(cTab)->RECZCQ)
				cIdenti := (cTab)->ZCQ_IDENTI
			else
				AADD(aFila2,(cTab)->RECZCQ)
			endif
			(cTab)->(dbSkip())
		END
	else
		(cTab)->(DbGoTop())
		WHILE (cTab)->(!EOF())
			AADD(aFila,(cTab)->RECZCQ)
			(cTab)->(dbSkip())
		END
	endif
	(cTab)->(dbCloseArea())

ELSEIF cTipoFila == "2"  // DW3
	
	// Realiza o callback para pegar o JSON
	dbselectarea("ZCS")

	cTab:= GetNextAlias()

	BeginSql Alias cTab
		SELECT R_E_C_N_O_ AS RECZCS
		FROM %TABLE:ZCS% ZCS
		WHERE ZCS_FILIAL = %xfilial:ZCS%
		  AND ZCS_STATUS = '0'
		  AND ZCS_FILA = %Exp:cFilPro%
		  AND ZCS_CODE = ''
		  AND ZCS.D_E_L_E_T_ = ''
	EndSql
	
	//aRet:= GETLastQuery()[2]

	aFila := {}
	(cTab)->(DbGoTop())
	WHILE (cTab)->(!EOF())
		AADD(aFila,(cTab)->RECZCS)
	(cTab)->(dbSkip())
	END
	(cTab)->(dbCloseArea())

	// Processamento em grid

	IF cGrid == "1"

		if Len(aFila) > 0

			oGrid := GridClient():New()
			
			lRet := oGrid:BatchExec("U_CRMQAMB",{cEmpAnt,cFilAnt},"U_CALLBACK",aFila)

			If !lRet .and. Empty(oGrid:aGridThreads)
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][Rabbit] Nenhum Agente do GRID disponivel no Momento")
			EndIf

			If !empty(oGrid:aErrorProc)
				varinfo('Lista de Erro',oGrid:aErrorProc)
			Endif

			If !empty(oGrid:aSendProc)
				varinfo('Não processado',oGrid:aSendProc)
			Endif

			for nX = 1 to Len(aFila)

				ZCS->(dbgoto(aFila[nX]))

				if ZCS->ZCS_STATUS == "1"

					cMsg := AllTrim(ZCS->ZCS_MSG)
					cMsg := StrTran(cMsg,'"','')
					cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
					cMsg := StrTran(cMsg,Chr(10)," ")
					
					Self:Sender('{"tipoEnvio":"'+ TRIM(ZCS->ZCS_TIPENV)  +'",'+;
									'"idEntidade":' + TRIM(ZCS->ZCS_IDENTI) +','+;
									'"idLog":' + AllTrim(Str(Val(ZCS->ZCS_IDLOG),15,0))+','+;
									'"status":"' + IIF(ZCS->ZCS_STATUS=="1","ERRO","PROCESSADO")+'",'+;
									'"resposta": {'+;
									'"Code": ' + TRIM(ZCS->ZCS_CODE) +','+;
									'"Message": "' + cMsg +'"}'+;
								'}')
				endif

			next

		endif
		
	else

		For nX:= 1 to len(aFila)
			
			IF !U_CALLBACK(aFila[nX])

				cMsg := AllTrim(ZCS->ZCS_MSG)
				cMsg := StrTran(cMsg,'"','')
				cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
				cMsg := StrTran(cMsg,Chr(10)," ")
				
				Self:Sender('{"tipoEnvio":"'+ TRIM(ZCS->ZCS_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCS->ZCS_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCS->ZCS_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCS->ZCS_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
								'"Code": ' + TRIM(ZCS->ZCS_CODE) +','+;
								'"Message": "' + cMsg +'"}'+;
							'}')
			ENDIF

		next

	endif
 
	(cTab)->(dbCloseArea())

	// Pega RECNO para processamento
	BeginSql Alias cTab
		SELECT R_E_C_N_O_ AS RECZCS,
			   ZCS_IDENTI
		FROM %TABLE:ZCS% ZCS
		WHERE ZCS_FILIAL = %xfilial:ZCS%
		  AND ZCS_STATUS = '0'
		  AND ZCS_FILA = %Exp:cFilPro%
		  AND ZCS_CODE = '200'
		  AND ZCS.D_E_L_E_T_ = ''
		ORDER BY ZCS_IDENTI, RECZCS
	EndSql

	//aRet:= GETLastQuery()[2]

	aFila  := {}
	aFila2 := {}

	// Processamento em grid
	IF cGrid == "1"
		cIdenti := space(15)
		(cTab)->(DbGoTop())
		WHILE (cTab)->(!EOF())
			if AllTrim(cIdenti) <> AllTrim((cTab)->ZCS_IDENTI)
				AADD(aFila,(cTab)->RECZCS)
				cIdenti := (cTab)->ZCS_IDENTI
			else
				AADD(aFila2,(cTab)->RECZCS)
			endif
			(cTab)->(dbSkip())
		END
	else
		(cTab)->(DbGoTop())
		WHILE (cTab)->(!EOF())
			AADD(aFila,(cTab)->RECZCS)
		(cTab)->(dbSkip())
		END
	endif
	(cTab)->(dbCloseArea())

ENDIF

IF !EMPTY(aFila)
	
	// Processamento em grid
	IF cGrid == "1"
		
		oGrid := GridClient():New()
		
		lRet := oGrid:BatchExec("U_CRMQAMB",{cEmpAnt,cFilAnt},cfnProc,aFila)

		If !lRet .and. Empty(oGrid:aGridThreads)
			CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][Rabbit] Nenhum Agente do GRID disponivel no Momento")
		EndIf

		If !empty(oGrid:aErrorProc)
			varinfo('Lista de Erro',oGrid:aErrorProc)
		Endif

		If !empty(oGrid:aSendProc)
			varinfo('Não processado',oGrid:aSendProc)
		Endif
/*
		For nX:= 1 to len(aFila)
			IF cTipoFila == "1"  // Kairos
				
				ZCQ->(dbgoto(aFila[nX]))

				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][INICIO] Retorno Kairos - " + CVALTOCHAR(ZCQ->(RECNO())) )

				cMsg := AllTrim(ZCQ->ZCQ_MSG)
				cMsg := StrTran(cMsg,'"','')
				cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
				cMsg := StrTran(cMsg,Chr(10)," ")

				Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
								'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
								'"Message": "' + cMsg +'"}'+;
							'}')

				// Gera movimento na fila DW3
				if cEnvDW3 == "1" .and. ZCQ->ZCQ_STATUS == "2"
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
						ZCS->ZCS_FILA  := cFilaDW3
						ZCS->ZCS_CODE  := "" //ZCQ->ZCQ_CODE
						ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
					MSUNLOCK()
				endif

				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][FIM] Retorno Kairos" + CVALTOCHAR(ZCQ->(RECNO())) )
			
			ELSEIF cTipoFila == "2"  // DW3
				
				ZCS->(dbgoto(aFila[nX]))

				cMsg := AllTrim(ZCS->ZCS_MSG)
				cMsg := StrTran(cMsg,'"','')
				cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
				cMsg := StrTran(cMsg,Chr(10)," ")

				Self:Sender('{"tipoEnvio":"'+ TRIM(ZCS->ZCS_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCS->ZCS_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCS->ZCS_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCS->ZCS_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
								'"Code": ' + TRIM(ZCS->ZCS_CODE) +','+;
								'"Message": "' + cMsg +'"}'+;
							'}')

			ENDIF
		Next
*/
	ELSE
		cfnProc:= STRTRAN(cfnProc,"U_","")
		For nX:= 1 to len(aFila)
			If ExistBlock(cfnProc)
				
				// Para ficar compativel com processamento em Grid
				&("U_"+cfnProc+"("+ CVALTOCHAR(aFila[nX]) +")")
/*				
				IF cTipoFila == "1"  // Kairos
					
					ZCQ->(dbgoto(aFila[nX]))

					cMsg := AllTrim(ZCQ->ZCQ_MSG)
					cMsg := StrTran(cMsg,'"','')
					cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
					cMsg := StrTran(cMsg,Chr(10)," ")

					Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
								 '"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
								 '"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
								 '"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								 '"resposta": {'+;
									'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
									'"Message": "' + cMsg +'"}'+;
								'}')

					// Gera movimento na fila DW3
					if cEnvDW3 == "1" .and. ZCQ->ZCQ_STATUS == "2"
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
							ZCS->ZCS_FILA  := cFilaDW3
							ZCS->ZCS_CODE  := "" //ZCQ->ZCQ_CODE
							ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
						MSUNLOCK()
					endif
				
				ELSEIF cTipoFila == "2"  // DW3
					
					ZCS->(dbgoto(aFila[nX]))

					cMsg := AllTrim(ZCS->ZCS_MSG)
					cMsg := StrTran(cMsg,'"','')
					cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
					cMsg := StrTran(cMsg,Chr(10)," ")

					Self:Sender('{"tipoEnvio":"'+ TRIM(ZCS->ZCS_TIPENV)  +'",'+;
								 '"idEntidade":' + TRIM(ZCS->ZCS_IDENTI) +','+;
								 '"idLog":' + AllTrim(Str(Val(ZCS->ZCS_IDLOG),15,0))+','+;
								 '"status":"' + IIF(ZCS->ZCS_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								 '"resposta": {'+;
									'"Code": ' + TRIM(ZCS->ZCS_CODE) +','+;
									'"Message": "' + cMsg +'"}'+;
								'}')

				ENDIF
*/
			ELSE
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][Rabbit] Funcao inexistente: U_" + cfnProc)
				EXIT
			ENDIF
		next
	ENDIF

EndIf

IF !EMPTY(aFila2)
	
	// Processamento em grid
	IF cGrid == "1" 
		
		oGrid := GridClient():New()
		
		lRet := oGrid:BatchExec("U_CRMQAMB",{cEmpAnt,cFilAnt},cfnProc,aFila2)

		If !lRet .and. Empty(oGrid:aGridThreads)
			CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][Rabbit] Nenhum Agente do GRID disponivel no Momento")
		EndIf

		If !empty(oGrid:aErrorProc)               
			varinfo('Lista de Erro',oGrid:aErrorProc)   
		Endif   

		If !empty(oGrid:aSendProc)                 
			varinfo('Não processado',oGrid:aSendProc)   
		Endif 
/*
		For nX:= 1 to len(aFila2)
			IF cTipoFila == "1"      //Kairos
				
				ZCQ->(dbgoto(aFila2[nX]))

				cMsg := AllTrim(ZCQ->ZCQ_MSG)
				cMsg := StrTran(cMsg,'"','')
				cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
				cMsg := StrTran(cMsg,Chr(10)," ")

				Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
								'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
								'"Message": "' + cMsg +'"}'+;
							'}')

				//Gera movimento na fila DW3
				if cEnvDW3 == "1" .and. ZCQ->ZCQ_STATUS == "2"
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
						ZCS->ZCS_FILA  := cFilaDW3 
						ZCS->ZCS_CODE  := "" //ZCQ->ZCQ_CODE
						ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
					MSUNLOCK()                
				endif
			
			ELSEIF cTipoFila == "2"  //DW3
				
				ZCS->(dbgoto(aFila2[nX]))

				cMsg := AllTrim(ZCS->ZCS_MSG)
				cMsg := StrTran(cMsg,'"','')
				cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
				cMsg := StrTran(cMsg,Chr(10)," ")

				Self:Sender('{"tipoEnvio":"'+ TRIM(ZCS->ZCS_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCS->ZCS_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCS->ZCS_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCS->ZCS_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
								'"Code": ' + TRIM(ZCS->ZCS_CODE) +','+;
								'"Message": "' + cMsg +'"}'+;
							'}')                    

			ENDIF
		Next            
*/
	ELSE
		cfnProc:= STRTRAN(cfnProc,"U_","")
		For nX:= 1 to len(aFila2)            
			If ExistBlock(cfnProc)
				
				//Para ficar compativel com processamento em Grid
				&("U_"+cfnProc+"("+ CVALTOCHAR(aFila2[nX]) +")")
/*							
				IF cTipoFila == "1"      //Kairos
					
					ZCQ->(dbgoto(aFila2[nX]))

					cMsg := AllTrim(ZCQ->ZCQ_MSG)
					cMsg := StrTran(cMsg,'"','')
					cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
					cMsg := StrTran(cMsg,Chr(10)," ")

					Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
								 '"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
								 '"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
								 '"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								 '"resposta": {'+;
									'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
									'"Message": "' + cMsg +'"}'+;
								'}')

					//Gera movimento na fila DW3
					if cEnvDW3 == "1" .and. ZCQ->ZCQ_STATUS == "2"
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
							ZCS->ZCS_FILA  := cFilaDW3 
							ZCS->ZCS_CODE  := "" //ZCQ->ZCQ_CODE
							ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
						MSUNLOCK()                
					endif                                
				
				ELSEIF cTipoFila == "2"  //DW3
					
					ZCS->(dbgoto(aFila2[nX]))

					cMsg := AllTrim(ZCS->ZCS_MSG)
					cMsg := StrTran(cMsg,'"','')
					cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
					cMsg := StrTran(cMsg,Chr(10)," ")

					Self:Sender('{"tipoEnvio":"'+ TRIM(ZCS->ZCS_TIPENV)  +'",'+;
								 '"idEntidade":' + TRIM(ZCS->ZCS_IDENTI) +','+;
								 '"idLog":' + AllTrim(Str(Val(ZCS->ZCS_IDLOG),15,0))+','+;
								 '"status":"' + IIF(ZCS->ZCS_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								 '"resposta": {'+;
									'"Code": ' + TRIM(ZCS->ZCS_CODE) +','+;
									'"Message": "' + cMsg +'"}'+;
								'}')                    

				ENDIF
*/
			ELSE
				CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][Rabbit] Funcao inexistente: U_"+cfnProc)
				EXIT
			ENDIF           
		next
	ENDIF           

EndIf

// Kairos e Gerar ZC5
if cTipoFila == "1"
	
	cTab := GetNextAlias()

	BeginSql Alias cTab
		SELECT DISTINCT ZC6.ZC6_IDFATU IDFATU,
		                ZC6.ZC6_FILIAL ZC6FILIAL
		FROM %TABLE:ZC6% ZC6
		WHERE ZC6.ZC6_GERZC5 = 'N'
		  AND ZC6.D_E_L_E_T_ = ''
	EndSql   

	//aRet:= GETLastQuery()[2]

	DbSelectArea("ZC6")
	ZC6->(DbSetOrder(04))

	aFila := {}
	(cTab)->(DbGoTop())
	while (cTab)->(!Eof())
		if ZC6->(DbSeek(PadR(AllTrim((cTab)->ZC6FILIAL),TamSX3("ZC6_FILIAL")[1])+(cTab)->IDFATU))
			AADD(aFila,ZC6->(RecNo()))
		endif
		(cTab)->(dbSkip())
	enddo
	
	(cTab)->(dbCloseArea())

	IF !Empty(aFila)
		
		// Processamento em grid
		IF cGrid == "1"
			
			oGrid := GridClient():New()
			
			lRet := oGrid:BatchExec("U_CRMQAMB",{cEmpAnt,cFilAnt},"U_GRAVAZC5",aFila)

			If !lRet .and. Empty(oGrid:aGridThreads)
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][Rabbit] Nenhum Agente do GRID disponivel no Momento")
			EndIf

			If !empty(oGrid:aErrorProc)
				varinfo('Lista de Erro',oGrid:aErrorProc)
			Endif

			If !empty(oGrid:aSendProc)
				varinfo('Não processado',oGrid:aSendProc)
			Endif

		ELSE

			cfnProc := "GRAVAZC5"
			For nX:= 1 to len(aFila)
				// Para ficar compativel com processamento em Grid
				&("U_" + cfnProc + "(" + CVALTOCHAR(aFila[nX]) + ")")
			next
		
		ENDIF

	EndIf

endif

// Kairos e Gerar ZC7
if cTipoFila == "1"
	
	cTab := GetNextAlias()

	BeginSql Alias cTab
		SELECT DISTINCT ZC8.ZC8_IDFOL IDFOL
		FROM %TABLE:ZC8% ZC8
		WHERE ZC8.ZC8_FILIAL = %xfilial:ZC8%
		  AND ZC8.ZC8_GERZC7 = 'N'
		  AND ZC8.D_E_L_E_T_ = ''
	EndSql   

	//aRet:= GETLastQuery()[2]

	DbSelectArea("ZC8")
	ZC8->(DbSetOrder(01))

	aFila := {}
	(cTab)->(DbGoTop())
	while (cTab)->(!Eof())
		if ZC8->(DbSeek((cTab)->IDFOL))
			AADD(aFila,ZC8->(RecNo()))
		endif
		(cTab)->(dbSkip())
	enddo
	
	(cTab)->(dbCloseArea())

	IF !Empty(aFila)
		
		// Processamento em grid
		IF cGrid == "1"
			
			oGrid := GridClient():New()
			
			lRet := oGrid:BatchExec("U_CRMQAMB",{cEmpAnt,cFilAnt},"U_GRAVAZC7",aFila)

			If !lRet .and. Empty(oGrid:aGridThreads)
				CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][Rabbit] Nenhum Agente do GRID disponivel no Momento")
			EndIf

			If !empty(oGrid:aErrorProc)
				varinfo('Lista de Erro',oGrid:aErrorProc)
			Endif

			If !empty(oGrid:aSendProc)
				varinfo('Não processado',oGrid:aSendProc)
			Endif

		ELSE

			cfnProc := "GRAVAZC7"
			For nX:= 1 to len(aFila)
				// Para ficar compativel com processamento em Grid
				&("U_" + cfnProc + "(" + CVALTOCHAR(aFila[nX]) + ")")
			next
		
		ENDIF

	EndIf

endif

/*
// Kairos e fila TCE/TCA
IF cTipoFila == "1" .and. (AllTrim(cFilPro) == "hfx-integracao-tce-tca-totvs" .or. AllTrim(cFilPro) == "ppd-integracao-tce-tca-totvs" .or.;
                           AllTrim(cFilPro) == "hmg-integracao-tce-tca-totvs" .or. AllTrim(cFilPro) == "dev1-integracao-tce-tca-totvs")

	//Pega RECNO para reprocessamento da integração TCE/TCA para os casos de período
	//Erro na IntegraçoAJUDA:HELP      
	//A CONFIGURAÇÃO DOS PERÍODOS ESTA INCORRETA OU NÃO EXISTE PERÍODO VÁLIDO PARA O ROTEIRO DE FÉRIAS. VERIFIQUE O CADASTRO DE PERÍODOS.
	cTab:= GetNextAlias()

	BeginSql Alias cTab
		SELECT R1.RECZCQ AS RECZCQ
		FROM (
			SELECT R_E_C_N_O_ AS RECZCQ ,
					ISNULL(CAST(CAST(ZCQ_MSG AS VARBINARY(8000)) AS VARCHAR(8000)),'') AS MSG
					FROM %TABLE:ZCQ% ZCQ 
					WHERE ZCQ_FILIAL=%xfilial:ZCQ%
						AND ZCQ_STATUS='1' 
						AND (ZCQ_FILA='hfx-integracao-tce-tca-totvs' OR ZCQ_FILA='ppd-integracao-tce-tca-totvs' OR ZCQ_FILA='hmg-integracao-tce-tca-totvs' OR ZCQ_FILA='dev1-integracao-tce-tca-totvs')
						AND ZCQ_CODE='404' 
						AND ZCQ.D_E_L_E_T_ =''    
			) R1
		WHERE R1.MSG LIKE '%A CONFIGURAÇÃO DOS PERÍODOS ESTA INCORRETA OU NÃO EXISTE PERÍODO VÁLIDO PARA O ROTEIRO DE FÉRIAS. VERIFIQUE O CADASTRO DE PERÍODOS.%'
	EndSql   

	//aRet:= GETLastQuery()[2]
	aFila:= {}
	WHILE (cTab)->(!EOF())	 
		AADD(aFila,(cTab)->RECZCQ)          
	(cTab)->(dbSkip())	
	END  
	
	(cTab)->(dbCloseArea())	    

	IF !EMPTY(aFila)
		
		//Processamento em grid
		IF cGrid == "1" 
			
			oGrid := GridClient():New()
			
			lRet := oGrid:BatchExec("U_CRMQAMB",{cEmpAnt,cFilAnt},cfnProc,aFila)

			If !lRet .and. Empty(oGrid:aGridThreads)
				CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][Rabbit] Nenhum Agente do GRID disponivel no Momento")
			EndIf

			If !empty(oGrid:aErrorProc)               
				varinfo('Lista de Erro',oGrid:aErrorProc)   
			Endif   

			If !empty(oGrid:aSendProc)                 
				varinfo('Não processado',oGrid:aSendProc)   
			Endif 

			For nX:= 1 to len(aFila)

				ZCQ->(dbgoto(aFila[nX]))

				cMsg := AllTrim(ZCQ->ZCQ_MSG)
				cMsg := StrTran(cMsg,'"','')
				cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
				cMsg := StrTran(cMsg,Chr(10)," ")

				Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
								'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
								'"Message": "' + cMsg +'"}'+;
							'}')

				//Gera movimento na fila DW3
				if cEnvDW3 == "1" .and. ZCQ->ZCQ_STATUS == "2"
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
						ZCS->ZCS_FILA  := cFilaDW3 
						ZCS->ZCS_CODE  := "" //ZCQ->ZCQ_CODE
						ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
					MSUNLOCK()                
				endif
			Next            

		ELSE
			cfnProc:= STRTRAN(cfnProc,"U_","")
			For nX:= 1 to len(aFila)            
				If ExistBlock(cfnProc)
					
					//Para ficar compativel com processamento em Grid
					&("U_"+cfnProc+"("+ CVALTOCHAR(aFila[nX]) +")")
						
					ZCQ->(dbgoto(aFila[nX]))

					cMsg := AllTrim(ZCQ->ZCQ_MSG)
					cMsg := StrTran(cMsg,'"','')
					cMsg := StrTran(cMsg,Chr(13)+Chr(10)," ")
					cMsg := StrTran(cMsg,Chr(10)," ")

					Self:Sender('{"tipoEnvio":"'+ TRIM(ZCQ->ZCQ_TIPENV)  +'",'+;
								'"idEntidade":' + TRIM(ZCQ->ZCQ_IDENTI) +','+;
								'"idLog":' + AllTrim(Str(Val(ZCQ->ZCQ_IDLOG),15,0))+','+;
								'"status":"' + IIF(ZCQ->ZCQ_STATUS=="1","ERRO","PROCESSADO")+'",'+;
								'"resposta": {'+;
									'"Code": ' + TRIM(ZCQ->ZCQ_CODE) +','+;
									'"Message": "' + cMsg +'"}'+;
								'}')

					//Gera movimento na fila DW3
					if cEnvDW3 == "1" .and. ZCQ->ZCQ_STATUS == "2"
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
							ZCS->ZCS_FILA  := cFilaDW3 
							ZCS->ZCS_CODE  := "" //ZCQ->ZCQ_CODE
							ZCS->ZCS_JSON  := ZCQ->ZCQ_JSON
						MSUNLOCK()                
					endif                                

				ELSE
					CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][Rabbit] Funcao inexistente: U_"+cfnProc)
					EXIT
				ENDIF           
			next
		ENDIF           

	EndIf

endif
*/

Return

/*/{Protheus.doc} CRMQAMB
Prepara ambiente GRID
@author carlos.henrique
@since 22/05/2019
@version undefined

@type function
/*/
USER Function CRMQAMB(aParms)
Local cEmpParm:= aParms[1]	// Empresa --> cEmpAnt
Local cFilParm:= aParms[2]	// Filial  --> cFilAnt

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][Rabbit] Preparando Ambiente")

RpcSetType(3)
RPCSetEnv(cEmpParm,cFilParm) 

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][Rabbit] Preparando Preparado")

Return .T.

/*/{Protheus.doc} CALLBACK
Rotina de CALLBACK
@author carlos.henrique
@since 01/01/2015
@version undefined
@param aBlocoMsg, array, descricao
@type user function
/*/
User Function CALLBACK(nRecno)

Local cToken

Local cTab    := GetNextAlias()
Local lRet    := .T.
Local oRet	  := nil
Local oRest   := Nil
Local aHeader := {}

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CALLBACK] INICIO RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("ZCT")
ZCT->(DbSetOrder(01))
ZCT->(DbGoTop())
cToken := AllTrim(ZCT->ZCT_TOKEN)

DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

IF ZCQ->(!Eof())

	cTab := GetNextAlias()

	BeginSql Alias cTab
		SELECT ZCP_TIPO
			  ,LTRIM(RTRIM(ZCP_URLCAL)) AS ZCP_URLCAL
			  ,LTRIM(RTRIM(ZCP_PTOKEN)) AS ZCP_PTOKEN
			  ,LTRIM(RTRIM(ZCP_USRCAL)) AS ZCP_USRCAL
			  ,LTRIM(RTRIM(ZCP_PSWCAL)) AS ZCP_PSWCAL
		FROM %TABLE:ZCP% ZCP 
		WHERE ZCP_FILIAL=%xfilial:ZCP%
			AND ZCP_TIPO='1'  
			AND ZCP_STATUS='1'
			AND ZCP_FILA=%Exp:ZCQ->ZCQ_FILA% 
			AND ZCP.D_E_L_E_T_ =''
		ORDER BY ZCP_ORDEM    		
	EndSql

	//aRet:= GETLastQuery()[2]
	
	IF (cTab)->(!EOF()) 
	 
//		IF GetToken(AllTrim((cTab)->ZCP_TIPO),AllTrim((cTab)->ZCP_URLCAL),AllTrim((cTab)->ZCP_PTOKEN),AllTrim((cTab)->ZCP_USRCAL),AllTrim((cTab)->ZCP_PSWCAL),@cToken)

			oRest := FWRest():New(AllTrim((cTab)->ZCP_URLCAL))

			aAdd(aHeader, 'Content-Type: application/json' )
			aAdd(aHeader, 'Authorization: Bearer ' + cToken )

			IF (cTab)->ZCP_TIPO == "1"      //Kairos
				oRest:setPath( ALLTRIM(ZCQ->ZCQ_URL) )
			ELSEIF (cTab)->ZCP_TIPO == "2"      //DW3
				oRest:setPath( ALLTRIM(ZCS->ZCS_URL) )
			endif

			oRet:= JsonObject():new()

			If oRest:GET(aHeader)  
				oRet:fromJSON( oRest:GetResult() )
				lRet  := .T.
			else    
				oRet:fromJSON( oRest:GetResult() )
				lRet := .F.
			Endif

			IF (cTab)->ZCP_TIPO == "1"      //Kairos

				RECLOCK("ZCQ",.F.)
					if oRest:GetHTTPCode()  == "200"
						ZCQ->ZCQ_CODE   := "200"
						ZCQ->ZCQ_JSON   := oRest:GetResult()                                              
					else
						ZCQ->ZCQ_STATUS := "1"
						ZCQ->ZCQ_MSG    := iif(Empty(oRet:GetJsonText("message")),"Erro na integração, por favor, enfileirar novamente.",oRet:GetJsonText("message"))
						ZCQ->ZCQ_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
						ZCQ->ZCQ_JSON   := oRet:toJson()            
					ENDIF    
				MSUNLOCK()    
				
			ELSEIF (cTab)->ZCP_TIPO == "2"  //DW3

				RECLOCK("ZCQ",.F.)
					if oRest:GetHTTPCode()  == "200"
						ZCS->ZCS_CODE   := "200"
						ZCS->ZCS_JSON   := oRest:GetResult()             
					Else
						ZCS->ZCS_STATUS := "1"
						ZCS->ZCS_MSG    := iif(Empty(oRet:GetJsonText("message")),"Erro na integração, por favor, enfileirar novamente.",oRet:GetJsonText("message"))
						ZCS->ZCS_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
						ZCS->ZCS_JSON   := oRet:toJson()                                                          
					ENDIF  
				MSUNLOCK()    

			endif
			
			FreeObj(oRet)
			FreeObj(oRest)

//		else
//		   lRet := .F.
//		endif
	endif
endif

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CALLBACK] FIM RECNO:" + CVALTOCHAR(nRecno))

Return(lRet)

/*/{Protheus.doc} GetToken
Método para pegar o token
@author carlos.henrique
@since 22/05/2019
@version undefined
@type function
/*/
/*Static function GetToken(cTpFila,cUrl,cPToken,cUser,cPsw,cToken)

Local oRest  := Nil
Local aHeader:= {}
Local cJSON  := ""
Local oRet	 := nil
Local lRet   := .T.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CALLBACK] INICIO TOKEN")

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

	IF cTpFila == "1"      //Kairos

		RECLOCK("ZCQ",.F.)
			ZCQ->ZCQ_STATUS := "1"
			ZCQ->ZCQ_MSG    := iif(Empty(oRet:GetJsonText("message")),"Erro na integração, por favor, enfileirar novamente.",oRet:GetJsonText("message"))
			ZCQ->ZCQ_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
			ZCQ->ZCQ_JSON   := oRet:toJson()              
		MSUNLOCK()    

	ELSEIF cTpFila == "2"  //DW3

		RECLOCK("ZCQ",.F.)
			ZCS->ZCS_STATUS := "1"
			ZCS->ZCS_MSG    := iif(Empty(oRet:GetJsonText("message")),"Erro na integração, por favor, enfileirar novamente.",oRet:GetJsonText("message"))
			ZCS->ZCS_CODE   := iif(Empty(oRet:GetJsonText("status")),"500",oRet:GetJsonText("status"))
			ZCS->ZCS_JSON   := oRet:toJson()              
		MSUNLOCK()    

	endif

	FreeObj(oRet)

Endif

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CALLBACK] FIM TOKEN")

Return(lRet)*/