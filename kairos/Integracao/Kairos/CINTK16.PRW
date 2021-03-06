#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK16
Servi�o de integra��o do local de contrato
@author danilo.grodzicki
@since 09/07/2020
@version P12.1.25
@type user function
/*/
USER FUNCTION CINTK16(nRecno)

Local cErro

Local cMsgOK := ""

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfCont    := space(002)
Private cCidCon    := space(050)
Private cDocLoc    := space(014)
Private cInsEst    := space(018)
Private cInsNum    := space(018)
Private cCepLoc    := space(008)
Private cLogLoc    := space(150)
Private cEndLoc    := space(150)
Private cNumLoc    := space(010)
Private cComLoc    := space(050)
Private cBaiLoc    := space(050)
Private cIdCoLo    := space(015)
Private cNoCoLo    := space(150)
Private cCaCoLo    := space(015)
Private cDeCoLo    := space(150)
Private cCodMunCon := space(050)
Private lErroTenta := .F.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK16] INICIO - Servi�o de integra��o do local de contrato - RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

IF !EMPTY(ZCQ->ZCQ_JSON)

	oJson:= JsonObject():new()
	oJson:fromJson(ZCQ->ZCQ_JSON)   
	
	cJson := ZCQ->ZCQ_JSON

	//Avalia o campo opera��o ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"I")
			if Empty(cErro)
				GravaCon(oJson)
				cMsgOK := "Local de contrato cadastrado com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"A")
			if Empty(cErro)
				// Realiza a altera��o do contrato e local de contrato
				GravaCon(oJson)
				cMsgOK := "Local de contrato alterado com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"E")

			if Empty(cErro)

				Begin Transaction
					
					if RecLock("ZC1",.F.)
						ZC1->(DbDelete())
						ZC1->(MsUnLock())
					endif

				End Transaction

				cMsgOK := "Local de contrato exclu�do com sucesso."
				
			endif
	
	ENDCASE

	FreeObj(oJson)

ELSE
	
	cErro := "JSON N�O INFORMADO"

ENDIF

RECLOCK("ZCQ",.F.)

	if !Empty(cErro)
		if lErroTenta
			ZCQ->ZCQ_QTDTEN := ZCQ->ZCQ_QTDTEN + 1
			if ZCQ->ZCQ_QTDTEN <= GetMv("CI_QTDTENT")
				// Reprocessar o registro
				ZCQ->ZCQ_STATUS := "0" 	
				ZCQ->ZCQ_CODE   := "200"
			else
				ZCQ->ZCQ_STATUS := "1" 	
				ZCQ->ZCQ_CODE   := "404"  // Erro
				ZCQ->ZCQ_MSG    := cErro
			endif
		else
			ZCQ->ZCQ_STATUS := "1" 	
			ZCQ->ZCQ_CODE   := "404"  // Erro
			ZCQ->ZCQ_MSG    := cErro
		endif
	else
		ZCQ->ZCQ_STATUS := "2" 	
		ZCQ->ZCQ_CODE   := "200" // Sucesso
		ZCQ->ZCQ_MSG    := cMsgOK
		ZCQ->ZCQ_QTDTEN := 0
	endif
	
MSUNLOCK()	

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK16] FIM - Servi�o de integra��o do local de contrato - RECNO:" + CVALTOCHAR(nRecno))

RETURN

/*/{Protheus.doc} INTEGRALOCALCONTRATO
Servi�o de integra��o do local de contrato
@author danilo.grodzicki
@since 09/07/2019
@version P12.1.25
@type class
/*/
WSRESTFUL INTEGRALOCALCONTRATO DESCRIPTION "Servi�o de integra��o do local de contrato" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza o cadastro do local de contrato";
	WSSYNTAX "/INTEGRALOCALCONTRATO"
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a atualiza��o do local de contrato";
	WSSYNTAX "/INTEGRALOCALCONTRATO"
	WSMETHOD DELETE; 
	DESCRIPTION "Realiza a exclus�o do local de contrato";
	WSSYNTAX "/INTEGRALOCALCONTRATO"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta do local de contrato";
	WSSYNTAX "/INTEGRALOCALCONTRATO"
END WSRESTFUL

/*/{Protheus.doc} POST
Realiza o cadastro do local de contrato
@author danilo.grodzicki
@since 09/07/2020
@/version P12.1.25

@type function
/*/
WSMETHOD POST WSSERVICE INTEGRALOCALCONTRATO

Local cErro

Local aRet := {}

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfCont    := space(002)
Private cCidCon    := space(050)
Private cDocLoc    := space(014)
Private cInsEst    := space(018)
Private cInsNum    := space(018)
Private cCepLoc    := space(008)
Private cLogLoc    := space(150)
Private cEndLoc    := space(150)
Private cNumLoc    := space(010)
Private cComLoc    := space(050)
Private cBaiLoc    := space(050)
Private cIdCoLo    := space(015)
Private cNoCoLo    := space(150)
Private cCaCoLo    := space(015)
Private cDeCoLo    := space(150)
Private cCodMunCon := space(050)
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"I")
if !Empty(cErro)
	U_GrvLogKa("CINTK16", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("INTEGRALOCALCONTRATO",oJson:toJSON(),"POST")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK16", "DW3POST", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a grava��o do local de contrato
GravaCon(oJson)

U_GrvLogKa("CINTK16", "POST", "1", "Integra��o realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integra��o realizada com sucesso")

/*/{Protheus.doc} PUT
Realiza a atualizacao do local de contrato
@author danilo.grodzicki
@since 09/07/2020
@version P12.1.25

@type function
/*/
WSMETHOD PUT WSSERVICE INTEGRALOCALCONTRATO

Local cErro

Local aRet := {}

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfCont    := space(002)
Private cCidCon    := space(050)
Private cDocLoc    := space(014)
Private cInsEst    := space(018)
Private cInsNum    := space(018)
Private cCepLoc    := space(008)
Private cLogLoc    := space(150)
Private cEndLoc    := space(150)
Private cNumLoc    := space(010)
Private cComLoc    := space(050)
Private cBaiLoc    := space(050)
Private cIdCoLo    := space(015)
Private cNoCoLo    := space(150)
Private cCaCoLo    := space(015)
Private cDeCoLo    := space(150)
Private cCodMunCon := space(050)
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"A")
if !Empty(cErro)
	U_GrvLogKa("CINTK16", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

// Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("INTEGRALOCALCONTRATO",oJson:toJSON(),"PUT")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK16", "DW3PUT", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a grava��o do local de contrato
GravaCon(oJson)

U_GrvLogKa("CINTK16", "PUT", "1", "Atualiza��o realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Atualiza��o realizada com sucesso")

/*/{Protheus.doc} DELETE
Realiza a exclus�o do local de contrato
@author danilo.grodzicki
@since 09/07/2020
@version P12.1.25

@type function
/*/
WSMETHOD DELETE WSSERVICE INTEGRALOCALCONTRATO

Local cErro

Local aRet  := {}
Local oJson := Nil

Private cJson      := Nil
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"E")
if !Empty(cErro)
	U_GrvLogKa("CINTK16", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

// Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("INTEGRALOCALCONTRATO",oJson:toJSON(),"DELETE") 
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK16", "DW3DELETE", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

Begin Transaction
	
	if RecLock("ZC1",.F.)
		ZC1->(DbDelete())
		ZC1->(MsUnLock())
	endif

End Transaction

U_GrvLogKa("CINTK16", "DELETE", "1", "Exclus�o realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Exclus�o realizada com sucesso")

/*/{Protheus.doc} GET
Realiza a consulta do local de contrato
@author Danilo Jos� Grodzicki
@since 09/07/2020
@/version P12.1.25

@type function
/*/
WSMETHOD GET WSSERVICE INTEGRALOCALCONTRATO

Local cErro

Local oJson := Nil
Local cJson := ""

Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"C")
if !Empty(cErro)
	U_GrvLogKa("CINTK16", "GET", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

cJson := '{'
cJson += '	"LOCALCONTRATO": {'
cJson += '		"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOCCTR), "cp1252") + '",'
cJson += '		"razaoSocial": "' + EncodeUTF8(AllTrim(ZC1->ZC1_RAZSOC), "cp1252") + '",'
cJson += '		"nomeFantasia": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOMFAN), "cp1252") + '",'
cJson += '		"documento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DOCLOC), "cp1252") + '",'
cJson += '		"inscricaoEstadual": "' + EncodeUTF8(AllTrim(ZC1->ZC1_INSEST), "cp1252") + '",'
cJson += '		"inscricaoMunicipal": "' + EncodeUTF8(AllTrim(ZC1->ZC1_INSMUN), "cp1252") + '",'
cJson += '		"ENDERECO": {'
cJson += '			"cep": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CEPLOC), "cp1252") + '",'
cJson += '			"logradouro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOGLOC), "cp1252") + '",'
cJson += '			"endereco": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ENDLOC), "cp1252") + '",'
cJson += '			"numero": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NUMLOC), "cp1252") + '",'
cJson += '			"complemento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_COMLOC), "cp1252") + '",'
cJson += '			"bairro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_BAILOC), "cp1252") + '",'
cJson += '			"codigoMunicipioIBGE": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CMUNLO), "cp1252") + '",'
cJson += '			"cidade": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CIDLOC), "cp1252") + '",'
cJson += '			"uf": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ESTLOC), "cp1252") + '"'
cJson += '		},'
cJson += '		"CONSULTOR": {'
cJson += '			"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_IDCOLO), "cp1252") + '",'
cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOCOLO), "cp1252") + '",'
cJson += '			"idCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CACOLO), "cp1252") + '",'
cJson += '			"dsCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DECOLO), "cp1252") + '"'
cJson += '		}'
cJson += '	},'
cJson += '}'

::SetResponse(cJson)

Return .T.

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author Danilo Jos� Grodzicki
@since 17/09/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

// Verifica se enviou o ID do contrato
cIdEmp := oJson["LOCALCONTRATO"]:GetJsonText("idContrato")
if Empty(cIdEmp)
	Return("O c�digo do contrato � obrig�torio.")
endif

// Verifica se enviou o ID do local do contrato
cIdLoc := oJson["LOCALCONTRATO"]:GetJsonText("id")
if Empty(cIdLoc)
	Return("O c�digo do local do contrato � obrigat�rio.")
endif

if cTipo == "I" .or. cTipo == "A"  // Inclus�o ou Altera��o

	// Verifica se o contrato est� cadastrado
	if !ZC0->(DbSeek(xFilial("ZC0")+Padr(AllTrim(cIdEmp),TamSX3("ZC0_CODIGO")[1]," ")))
		lErroTenta := .T.
		Return( "O contrato " + AllTrim(cIdEmp) + " n�o existe." )
	endif
	
elseif cTipo == "E" .or. cTipo == "C"  // Exclus�o ou Consulta
	
	// Verifica se o contrato e o local do contrato est� cadastrado
	if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdEmp),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cIdLoc),TamSX3("ZC1_LOCCTR")[1]," ")))
		lErroTenta := .T.
		Return("O contrato " + AllTrim(cIdEmp) + " e o local do contrato " + AllTrim(cIdLoc) + " n�o existe.")
	endif

	Return("")

endif

// Verifica se envio a raz�o social
cRazSoc := DecodeUTF8(oJson["LOCALCONTRATO"]:GetJsonText("razaoSocial"))
if Empty(cRazSoc)
	Return("A raz�o social do local do contrato � obrigat�rio.")
endif

// Verifica se enviou o n�mero do documento (CNPJ Empresa / CPF Profissional Liberal)
cDocLoc := oJson["LOCALCONTRATO"]:GetJsonText("documento")
if Empty(cDocLoc)
	Return("O n�mero do documento (CNPJ Empresa / CPF Profissional Liberal) do local do contrato � obrigat�rio.")
endif

// Verifica se enviou o estado do endere�o do local do contrato
cUfCont := oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("uf")
if Empty(cUfCont)
	Return("O estado do endere�o do local do contrato � obrigat�rio.")
endif

// Verifica se enviou o c�digo do munic�pio do endere�o do local do contrato
cCodMunCon := oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("codigoMunicipioIBGE")
if Empty(cCodMunCon)
	Return("O c�digo do munic�pio do endere�o do local do contrato � obrigat�rio.")
endif

// Verifica se o estado e c�digo do munic�pio do endere�o do local do contrato s�o v�lidos
if !CC2->(DbSeek(xFilial("CC2")+cUfCont+cCodMunCon))
	Return("O estado " + AllTrim(cUfCont) + "e/ou c�digo do municipio " + AllTrim(cCodMunCon) + " do endere�o do local do contrato inv�lido.")
endif
cCidCon := AllTrim(CC2->CC2_MUN)

// Faz a valida��o caso seja enviada a inscri��o estadual
cInsEst := oJson["LOCALCONTRATO"]:GetJsonText("inscricaoEstadual")
if !Empty(cInsEst)
	if AllTrim(cUfCont) == "DF"  // Distrito Federal deve-se acrescentar um 0 (zero) � esquerda.
		cInsEst := "0" + AllTrim(cInsEst)
	else
		cInsEst := AllTrim(cInsEst)
	endif
    if !IE(cInsEst, AllTrim(cUfCont), .F.)
	    Return("Inscri��o Estadual " + AllTrim(cInsEst) + " inv�lida.")
    endif
endif

Return("")

/*/{Protheus.doc} GravaCon
Realiza a grava��o do local de contrato
@author TOTVS
@since 18/09/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function GravaCon(oJson)

//Local lInclui

// Verifica se o local do contrato est� cadastrado
//if ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdEmp),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cIdLoc),TamSX3("ZC1_LOCCTR")[1]," ")))
//	lInclui := .F.  // Altera��o
//else
//	lInclui := .T.  // Inclus�o
//endif

cRazSoc := DecodeUTF8(oJson["LOCALCONTRATO"]:GetJsonText("razaoSocial"))
cNomFan := DecodeUTF8(oJson["LOCALCONTRATO"]:GetJsonText("nomeFantasia"))
cDocLoc := oJson["LOCALCONTRATO"]:GetJsonText("documento")
cInsEst := oJson["LOCALCONTRATO"]:GetJsonText("inscricaoEstadual")
cInsNum := oJson["LOCALCONTRATO"]:GetJsonText("inscricaoMunicipal")
cCepLoc := oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("cep")
cLogLoc := DecodeUTF8(oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("logradouro"))
cEndLoc := DecodeUTF8(oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("endereco"))
cNumLoc := oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("numero")
cComLoc := DecodeUTF8(oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("complemento"))
cBaiLoc := DecodeUTF8(oJson["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("bairro"))
cIdCoLo := oJson["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("id")
cNoCoLo := DecodeUTF8(oJson["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("nome"))
cCaCoLo := oJson["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("idCarteira")
cDeCoLo := DecodeUTF8(oJson["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("dsCarteira"))

Begin Transaction
	
	Sleep(500)

	ZC1->(DbSetOrder(01))
	if ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdEmp),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cIdLoc),TamSX3("ZC1_LOCCTR")[1]," ")))
		RecLock("ZC1",.F.)
	else
		RecLock("ZC1",.T.)
	endif
		ZC1->ZC1_FILIAL := xFilial("ZC1")
		ZC1->ZC1_CODIGO := cIdEmp
		ZC1->ZC1_LOCCTR := cIdLoc
		ZC1->ZC1_RAZSOC := cRazSoc
		ZC1->ZC1_NOMFAN := iif(Empty(cNomFan),cRazSoc,cNomFan)
		ZC1->ZC1_DOCLOC := cDocLoc
		ZC1->ZC1_INSEST := cInsEst
		ZC1->ZC1_INSMUN := cInsNum
		ZC1->ZC1_CEPLOC := cCepLoc
		ZC1->ZC1_LOGLOC := cLogLoc
		ZC1->ZC1_ENDLOC := cEndLoc
		ZC1->ZC1_NUMLOC := cNumLoc
		ZC1->ZC1_COMLOC := cComLoc
		ZC1->ZC1_BAILOC := cBaiLoc
		ZC1->ZC1_CMUNLO := cCodMunCon
		ZC1->ZC1_CIDLOC := cCidCon
		ZC1->ZC1_ESTLOC := cUfCont
		ZC1->ZC1_IDCOLO := cIdCoLo
		ZC1->ZC1_NOCOLO := cNoCoLo
		ZC1->ZC1_CACOLO := cCaCoLo
		ZC1->ZC1_DECOLO := cDeCoLo
		ZC1->ZC1_DTINTE := Date()
		ZC1->ZC1_HRINTE := Time()
		ZC1->ZC1_JSON   := cJson
	ZC1->(MsUnLock())

End Transaction

Return Nil