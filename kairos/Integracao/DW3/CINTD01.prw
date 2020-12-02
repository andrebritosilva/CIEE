#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} CINTD01
Envia dados da integração do contrato e local de contrato para o DW3
@author Danilo José Grodzicki
@since 01/03/2019
@version undefined
@type class
/*/
User function CINTD01(cServ,cJson,cVerbo)


Local cDW3_URL  := ""
Local cDW3_Path := ""
Local aHeader   := {}
Local aRet      := {}

if AllTrim(GetEnvServer()) == "CDPRXC_HOM_REST"      // ambiente homologação.
	if FWCodEmp() = "02"  // CIEE - São Paulo - MIGRAÇÃO
		cDW3_URL := "https://financeiro.cob360.com.br"
	else
		cDW3_URL := ALLTRIM(GetMV("CI_URLDW3H",.T.,"http://homol.financeiro.cob360.com.br"))
	endif
elseif AllTrim(GetEnvServer()) == "CDPRXC_TSTSP_WS"  // ambiente teste.
	cDW3_URL := ALLTRIM(GetMV("CI_URLDW3T",.T.,"http://dev.financeiro.cob360.com.br"))
endif

if AllTrim(cDW3_URL) == "DESLIGA"
	aadd(aRet,{.T.,""})
	Return(aRet)
endif

IF EMPTY(cDW3_URL)
	aadd(aRet,{.T.,"Url de integração com a DW3 não foi preenchido."})
	Return(aRet)
ENDIF

DO CASE
	CASE cServ == "INTEGRACONTRATO"
		cDW3_Path := "/api/pagador/protheus/contrato"
	CASE cServ == "INTEGRALOCALCONTRATO"
		cDW3_Path := "/api/pagador/protheus/local"
	CASE cServ == "TCETCA"
		cDW3_Path := "/api/pagador/protheus/estagiario"		
	CASE cServ == "CONFIGFAT"
		cDW3_Path := "/api/pagador/protheus/faturamento"
	CASE cServ == "CONFIGCOB"
		cDW3_Path := "/api/pagador/protheus/cobranca"
	CASE cServ == "COBRANCA_DW3"
		cDW3_Path := "/api/fatura/job"		
ENDCASE

oDw3:= FWRest():New(cDW3_URL)

Aadd(aHeader,'Content-Type: application/json;charset=utf-8')
Aadd(aHeader,'Accept: application/json')

oDw3:setPath(cDW3_Path)

if cVerbo == "POST"
	oDw3:SetPostParams(cJson)
	oDw3:Post(aHeader)
elseif cVerbo == "PUT"
	oDw3:Put(aHeader,cJson)
elseif cVerbo == "DELETE"
	oDw3:Delete(aHeader,cJson)
endif

/*
IF Empty(oDw3:CINTERNALERROR)
	oRet:= JsonObject():new()
	oRet:fromJson(oDw3:GetResult())
	if !Empty(oRet:GetJsonText("status"))
		aadd(aRet,{.F.,"DW3: " + AllTrim(oRet:GetJsonText("status")) + " - " + AllTrim(oRet:GetJsonText("message")) })
	else
		aadd(aRet,{.T.,""})
	endif
else
	aadd(aRet,{.F., oDw3:CINTERNALERROR})
endif
*/

if oDw3:GetHTTPCode() == "200" .or. oDw3:GetHTTPCode() == "201"
	aadd(aRet,{.T.,""})
else
	IF Empty(oDw3:CINTERNALERROR)
		oRet:= JsonObject():new()
		oRet:fromJson(oDw3:GetResult())
		if !Empty(oRet:GetJsonText("status"))
			aadd(aRet,{.F.,"Código " + AllTrim(oDw3:GetHTTPCode()) + " - " + AllTrim(oRet:GetJsonText("status")) + " - " + AllTrim(oRet:GetJsonText("message")) })
		elseif !Empty(oDw3:GetResult())
			aadd(aRet,{.F.,"Código " + AllTrim(oDw3:GetHTTPCode()) + " - " + AllTrim(oDw3:GetResult()) })
		else
			aadd(aRet,{.F.,"ERRO INTEGRAÇÃO - Código " + AllTrim(oDw3:GetHTTPCode()) })
		endif
	else
		aadd(aRet,{.F., oDw3:CINTERNALERROR})
	endif
endif

Return(aRet)