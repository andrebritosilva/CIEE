#include 'totvs.ch'
#include 'parmtype.ch'
#include 'restful.ch'

/*/{Protheus.doc} CINTK12
Rotina de autenticação com Kairos para buscar Token
@author marcelo.moraes
@since 30/04/2019
@version undefined
@type function
@return token
/*/
USER FUNCTION CINTK12()
Local cUrlServ 	:= ALLTRIM(GetMv("CI_KAIROS",.F.,"https://api.hmg.ciee.org.br"))  // URL do serviço
Local cPathOuth := ALLTRIM(GetMv("CI_PTOUTH",.F.,"/auth/login"))                  // Path do Outh  
Local cUsrKairos:= ALLTRIM(GetMv("CI_USRKAI",.F.,"admin4@admin.user.ciee"))       // Usuário de autenticação KAIROS
Local cPswKairos:= ALLTRIM(GetMv("CI_PSWKAI",.F.,"123456"))                       // Senha de autenticação KAIROS  
Local oRest 	:= Nil
Local aHeader   := {}
Local cJSON     := ""
Local cToken	:= " "
Local oRet		:= nil

cJSON+= '{'
cJSON+= '   "password": "'+cPswKairos+'", '
cJSON+= '   "username": "'+cUsrKairos+'"  '
cJSON+= '}'

aAdd(aHeader, 'Content-Type: application/json' )
aAdd(aHeader, 'Accept: application/json'       )

oRest := FWRest():New(cUrlServ)
oRest:setPath(cPathOuth)
oRest:SetPostParams(cJSON)

If oRest:Post(aHeader)
	oRet:= JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )
	cToken:= oRet["token"]
	FreeObj(oRet)
Endif

Return cToken