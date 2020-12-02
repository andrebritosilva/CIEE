#INCLUDE "TOTVS.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} CJOBK11
JOB para pegar o Token Kairós
@author danilo.grodzicki
@since 13/08/2020
@version undefined
@type user function
/*/
User Function CJOBK11(aParam)

Local cEmp
Local cFil

Local lJob		:= GetRemoteType() == -1 // Verifica se é job
Local nOpca		:= 0

cEmp := alltrim(aParam[1])
cFil := alltrim(aParam[2])

IF !lJob
	if RetCodUsr() <> "000000"  // Admin
		MsgInfo("Você não tem permissão para pegar o Token Kairós","ATENÇÃO")
		Return
	endif
	IF MSGYESNO("Confirma o processamento para pegar o Token Kairós?")
		nOpca := 1
	ENDIF
ELSE
	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK11] Iniciando processamento para pegar o Token Kairós via schedule.")
	nOpca := 1
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK11PR(lJob) },,"Realizando processo para pegar o Token Kairós, aguarde...")
		UnLockByName("CJOBK11")
	ELSE
		RpcSetType(3)
		RpcSetEnv(cEmp,cFil)
		IF !LockByName("CJOBK11")
			CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CJOBK11] Já existe um processamento em execução, aguarde!")
		ELSE
			CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK11] Processo pegar Token Kairós Iniciado para " + CEMPANT + "-" + CFILANT )
			CJBK11PR(lJob)
			CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK11] Processo pegar Token Kairós Finalizado para " + CEMPANT + "-" + CFILANT )
			UnLockByName("CJOBK11")
		ENDIF
		RpcClearEnv()
	ENDIF
	
ENDIF

Return

/*/{Protheus.doc} CJBK11PR
Rotina de processamento para pegar Token Kairós
@author danilo.grodzicki
@since 13/08/2020
@version undefined
@type user function
/*/
Static Function CJBK11PR(lJob)

Local cUrl
Local cPsw
Local cUser
Local cPToken

Local cRet    := ""
Local oRet	  := Nil
Local oRest   := Nil
Local cJSON   := ""
Local aHeader := {}

CONOUT( "[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "] INICIO TOKEN" )

DbSelectArea("ZCT")
ZCT->(DbSetOrder(01))
ZCT->(DbGoTop())

if ElapTime(ZCT->ZCT_HTOKEN, Time()) < GetMv("CI_SEGTOKE")
	Return
endif

cUrl    := AllTrim(ZCT->ZCT_URLCAL)
cUser   := AllTrim(ZCT->ZCT_USRCAL)
cPsw    := AllTrim(ZCT->ZCT_PSWCAL)
cPToken := AllTrim(ZCT->ZCT_PTOKEN)

cJSON += '{'
cJSON += '   "username": "' + cUser + '",'
cJSON += '   "password": "' + cPsw + '"'
cJSON += '}'

aAdd(aHeader, 'Content-Type: application/json' )
aAdd(aHeader, 'Accept: application/json'       )

oRest := FWRest():New(cUrl)
oRest:setPath(cPToken)
oRest:SetPostParams(cJSON)

If oRest:Post(aHeader)

	oRet := JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )

	RecLock("ZCT",.F.)
		ZCT->ZCT_TOKEN  := oRet["token"]
		ZCT->ZCT_DTOKEN := Date()
		ZCT->ZCT_HTOKEN := Time()
	MsUnLock()

ELSE

 	oRet := JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )

	cRet := oRet:GetJsonText("status") + " - " + oRet:GetJsonText("message")

	RecLock("ZCT",.F.)
		ZCT->ZCT_TOKEN  := cRet
		ZCT->ZCT_DTOKEN := Date()
		ZCT->ZCT_HTOKEN := Time()
	MsUnLock()

Endif

FreeObj(oRet)

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"] FIM TOKEN")

Return

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author carlos.henrique
@since 06/06/2019
@version undefined

@type function
/*/
/*Static Function Scheddef()
Local aParam := {"P","CJOBK11","",{},""}    
Return aParam*/