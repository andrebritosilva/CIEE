#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK17
Serviço de integração do contrato
@author danilo.grodzicki
@since 09/07/2020
@version undefined
@type function
/*/
USER FUNCTION CINTK17(nRecno)

Local cErro

Local cMsgOK := ""

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cNome      := space(150)
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfEmp     := space(002)
Private cTipCon    := space(001)
Private cTipApe    := space(001)
Private cForPgt    := space(001)
Private cCidEmp    := space(050)
Private cPrgApe    := space(250)
Private cTipEmp    := space(015)
Private cStEmpr    := space(018)
Private cNReduz    := space(150)
Private cNumDoc    := space(014)
Private cStConv    := space(001)
Private cCepEmp    := space(008)
Private cLogEmp    := space(150)
Private cEndEmp    := space(150)
Private cNumEmp    := space(010)
Private cComEmp    := space(050)
Private cBaiEmp    := space(050)
Private cIdCoEn    := space(015)
Private cNoCoEn    := space(150)
Private cCaCoEn    := space(015)
Private cDeCoEn    := space(150)
Private cCodMunEmp := space(050)

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK17] INICIO - Serviço de integração do contrato - RECNO:" + CVALTOCHAR(nRecno))

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

	//Avalia o campo operação ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"I")
			if Empty(cErro)
				GravaCon(oJson)
				cMsgOK := "Cotrato cadastrado com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"A")
			if Empty(cErro)
				// Realiza a alteração do contrato e local de contrato
				GravaCon(oJson)
				cMsgOK := "Cotrato alterado com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"E")

			if Empty(cErro)

				Begin Transaction
					
					if RecLock("ZC0",.F.)
						ZC0->(DbDelete())
						ZC0->(MsUnLock())
					endif
					
					while ZC1->(DbSeek(xFilial("ZC1")+Padr(AllTrim(cIdEmp),TamSX3("ZC1_CODIGO")[1]," ")))
						if RecLock("ZC1",.F.)
							ZC1->(DbDelete())
							ZC1->(MsUnLock())
						endif
					enddo

				End Transaction

				cMsgOK := "Cotrato excluído com sucesso."

			endif
	
	ENDCASE

	FreeObj(oJson)

ELSE
	
	cErro := "JSON NÃO INFORMADO"

ENDIF

RECLOCK("ZCQ",.F.)

	if !Empty(cErro)
		ZCQ->ZCQ_STATUS := "1" 	
		ZCQ->ZCQ_CODE   := "404"  // Erro
		ZCQ->ZCQ_MSG    := cErro
	else
		ZCQ->ZCQ_STATUS := "2" 	
		ZCQ->ZCQ_CODE   := "200" // Sucesso
		ZCQ->ZCQ_MSG    := cMsgOK
	endif
	
MSUNLOCK()	

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK17] FIM - Serviço de integração do contrato - RECNO:" + CVALTOCHAR(nRecno))

RETURN

/*/{Protheus.doc} INTEGRACONTRATO
Serviço de integração do contrato
@author danilo.grodzicki
@since 09/07/2020
@version undefined
@type class
/*/
WSRESTFUL INTEGRACONTRATO DESCRIPTION "Serviço de integração do contrato" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza o cadastro do contrato";
	WSSYNTAX "/INTEGRACONTRATO"
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a atualização do contrato";
	WSSYNTAX "/INTEGRACONTRATO"
	WSMETHOD DELETE; 
	DESCRIPTION "Realiza a exclusão do contrato";
	WSSYNTAX "/INTEGRACONTRATO"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta do contrato";
	WSSYNTAX "/INTEGRACONTRATO"
END WSRESTFUL

/*/{Protheus.doc} POST
Realiza o cadastro do contrato
@author danilo.grodzicki
@since 09/07/2020
@/version undefined

@type function
/*/
WSMETHOD POST WSSERVICE INTEGRACONTRATO

Local cErro

Local aRet := {}

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cNome      := space(150)
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfEmp     := space(002)
Private cTipCon    := space(001)
Private cTipApe    := space(001)
Private cForPgt    := space(001)
Private cCidEmp    := space(050)
Private cPrgApe    := space(250)
Private cTipEmp    := space(015)
Private cStEmpr    := space(018)
Private cNReduz    := space(150)
Private cNumDoc    := space(014)
Private cStConv    := space(001)
Private cCepEmp    := space(008)
Private cLogEmp    := space(150)
Private cEndEmp    := space(150)
Private cNumEmp    := space(010)
Private cComEmp    := space(050)
Private cBaiEmp    := space(050)
Private cIdCoEn    := space(015)
Private cNoCoEn    := space(150)
Private cCaCoEn    := space(015)
Private cDeCoEn    := space(150)
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""
Private cCodMunEmp := space(050)

dbSelectArea("ZC0")
ZC0->(dbSetOrder(1))

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"I")
if !Empty(cErro)
	U_GrvLogKa("CINTK17", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("INTEGRACONTRATO",oJson:toJSON(),"POST")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK17", "DW3POST", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a gravação do contrato e local de contrato
GravaCon(oJson)

U_GrvLogKa("CINTK17", "POST", "1", "Integração realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integração realizada com sucesso")

/*/{Protheus.doc} PUT
Realiza a atualizacao do contrato
@author danilo.grodzicki
@since 09/07/2020
@version undefined

@type function
/*/
WSMETHOD PUT WSSERVICE INTEGRACONTRATO

Local cErro

Local aRet := {}

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cNome      := space(150)
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfEmp     := space(002)
Private cTipCon    := space(001)
Private cTipApe    := space(001)
Private cForPgt    := space(001)
Private cCidEmp    := space(050)
Private cPrgApe    := space(250)
Private cTipEmp    := space(015)
Private cStEmpr    := space(018)
Private cNReduz    := space(150)
Private cNumDoc    := space(014)
Private cStConv    := space(001)
Private cCepEmp    := space(008)
Private cLogEmp    := space(150)
Private cEndEmp    := space(150)
Private cNumEmp    := space(010)
Private cComEmp    := space(050)
Private cBaiEmp    := space(050)
Private cIdCoEn    := space(015)
Private cNoCoEn    := space(150)
Private cCaCoEn    := space(015)
Private cDeCoEn    := space(150)
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""
Private cCodMunEmp := space(050)

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("CC2")
CC2->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"A")
if !Empty(cErro)
	U_GrvLogKa("CINTK17", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

// Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("INTEGRACONTRATO",oJson:toJSON(),"PUT")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK17", "DW3PUT", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a gravação do contrato e local de contrato
GravaCon(oJson)

U_GrvLogKa("CINTK17", "PUT", "1", "Atualização realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Atualização realizada com sucesso")

/*/{Protheus.doc} DELETE
Realiza a exclusão do contrato
@author danilo.grodzicki
@since 09/07/2020
@version undefined

@type function
/*/
WSMETHOD DELETE WSSERVICE INTEGRACONTRATO

Local cErro

Local aRet  := {}
Local oJson := Nil

Private cJson      := Nil
Private cIdEmp     := space(015)
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"E")
if !Empty(cErro)
	U_GrvLogKa("CINTK17", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

// Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("INTEGRACONTRATO",oJson:toJSON(),"DELETE") 
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK17", "DW3DELETE", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

Begin Transaction
	
 	if RecLock("ZC0",.F.)
		ZC0->(DbDelete())
		ZC0->(MsUnLock())
	endif

	while ZC1->(DbSeek(xFilial("ZC1")+Padr(AllTrim(cIdEmp),TamSX3("ZC1_CODIGO")[1]," ")))
		if RecLock("ZC1",.F.)
			ZC1->(DbDelete())
			ZC1->(MsUnLock())
		endif
	enddo

End Transaction

U_GrvLogKa("CINTK17", "DELETE", "1", "Exclusão realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Exclusão realizada com sucesso")

/*/{Protheus.doc} GET
Realiza a consulta do contrato
@author danilo.grodzicki
@since 09/07/2020
@/version undefined

@type function
/*/
WSMETHOD GET WSSERVICE INTEGRACONTRATO

Local cErro

Local oJson := Nil
Local cJson := ""

Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"C")
if !Empty(cErro)
	U_GrvLogKa("CINTK17", "GET", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

cJson := '{'
cJson += '	"EMPRESA": {'
cJson += '		"idContrato": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CODIGO), "cp1252") + '",'
cJson += '      "tipoContrato": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPCON), "cp1252") + '",'
cJson += '		"tipoAprendiz": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPAPR), "cp1252") + '",'
cJson += '		"programaAprendizagem": "' + EncodeUTF8(AllTrim(ZC0->ZC0_PRGAPE), "cp1252") + '",'
cJson += '		"tipoEmpresa": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPEMP), "cp1252") + '",'
cJson += '		"razaoSocial": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NOME), "cp1252") + '",'
cJson += '		"nomeFantasia": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NREDUZ), "cp1252") + '",'
cJson += '		"documento": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NUMDOC), "cp1252") + '",'
cJson += '		"sitcontrato": "' + EncodeUTF8(AllTrim(ZC0->ZC0_STCONV), "cp1252") + '",'
cJson += '		"sitempresa": "' + EncodeUTF8(AllTrim(ZC0->ZC0_STEMPR), "cp1252") + '",'
cJson += '		"formaPagamento": "' + EncodeUTF8(AllTrim(ZC0->ZC0_TIPCON), "cp1252") + '",'
cJson += '		"ENDERECO": {'
cJson += '			"cep": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CEPEMP), "cp1252") + '",'
cJson += '			"logradouro": "' + EncodeUTF8(AllTrim(ZC0->ZC0_LOGEMP), "cp1252") + '",'
cJson += '			"endereco": "' + EncodeUTF8(AllTrim(ZC0->ZC0_ENDEMP), "cp1252") + '",'
cJson += '			"numero": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NUMEMP), "cp1252") + '",'
cJson += '			"complemento": "' + EncodeUTF8(AllTrim(ZC0->ZC0_COMEMP), "cp1252") + '",'
cJson += '			"bairro": "' + EncodeUTF8(AllTrim(ZC0->ZC0_BAIEMP), "cp1252") + '",'
cJson += '			"codigoMunicipioIBGE": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CMUNEM), "cp1252") + '",'
cJson += '			"cidade": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CIDEMP), "cp1252") + '",'
cJson += '			"uf": "' + EncodeUTF8(AllTrim(ZC0->ZC0_ESTEMP), "cp1252") + '"'
cJson += '		},'
cJson += '		"CONSULTOR": {'
cJson += '			"id": "' + EncodeUTF8(AllTrim(ZC0->ZC0_IDCOEN), "cp1252") + '",'
cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC0->ZC0_NOCOEN), "cp1252") + '",'
cJson += '			"idCarteira": "' + EncodeUTF8(AllTrim(ZC0->ZC0_CACOEN), "cp1252") + '",'
cJson += '			"dsCarteira": "' + EncodeUTF8(AllTrim(ZC0->ZC0_DECOEN), "cp1252") + '"'
cJson += '		},'

oRepres:= JsonObject():new()
oRepres:fromJson(AllTrim(ZC0->ZC0_REPR))
cRepres:= oRepres:TOJSON()
cRepres:= RIGHT(cRepres,LEN(cRepres)-1)
cRepres:= LEFT(cRepres,LEN(cRepres)-1)

cJson += cRepres+","

oContat:= JsonObject():new()
oContat:fromJson(AllTrim(ZC0->ZC0_CONTAT))
cContat:= oContat:TOJSON()
cContat:= RIGHT(cContat,LEN(cContat)-1)
cContat:= LEFT(cContat,LEN(cContat)-1)

cJson += cContat

cJson += '	}'
cJson += '}'

::SetResponse(cJson)

Return .T.

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author danilo.grodzicki
@since 09/07/2020
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

Local nI

// Verifica se enviou o ID do contrato
cIdEmp := oJson["EMPRESA"]:GetJsonText("idContrato")
if Empty(cIdEmp)
	Return("O código do contrato é obrigátorio.")
endif

if cTipo == "E" .or. cTipo == "C"  // Exclusão ou Consulta
	
	// Verifica se o contrato está cadastrado
	if !ZC0->(DbSeek(xFilial("ZC0")+Padr(AllTrim(cIdEmp),TamSX3("ZC0_CODIGO")[1]," ")))
		Return( "O contrato " + AllTrim(cIdEmp) + " não existe." )
	endif
	
	Return("")

endif

// Verifica se o tipo de contrato da Empresa é válido
cTipCon := oJson["EMPRESA"]:GetJsonText("tipoContrato")
if Empty(cTipCon) .or. !(cTipCon $ "12")
	Return("Tipo de contrato da empresa " + AllTrim(cTipCon) + " inválido.")
endif

// Verifica se o tipo de aprendiz da empresa é válido
cTipApe := oJson["EMPRESA"]:GetJsonText("tipoAprendiz")
	
if cTipCon == "2"  // Aprendiz
	if Empty(cTipApe) .or. !(cTipApe $ "12")
		Return("Tipo aprendiz da empresa " + AllTrim(cTipApe) + " inválido.")
	endif
endif

// Verifica se o tipo de empresa é válido
cTipEmp := oJson["EMPRESA"]:GetJsonText("tipoEmpresa")
if Empty(cTipEmp) .or. !(cTipEmp $ "123")
	Return("Tipo de empresa " + AllTrim(cTipEmp) + " inválido.")
endif

// Verifica se enviou a razão social de empresa
cNome := DecodeUTF8(oJson["EMPRESA"]:GetJsonText("razaoSocial"))
if Empty(cNome)
	Return("Razão social da empresa é obrigatório.")
endif

// Verifica se enviou o número do documento (CNPJ Empresa ou CPF Profissional Liberal)
cNumDoc := oJson["EMPRESA"]:GetJsonText("documento")
if Empty(cNumDoc)
	Return("Número do documento (CNPJ Empresa ou CPF Profissional Liberal) é obrigatório.")
endif

// Verifica se a situação do contrato da empresa é válido
cStConv := oJson["EMPRESA"]:GetJsonText("sitcontrato")
if Empty(cStConv) .or. !(cStConv $ "01")
	Return("Situação do contrato da empresa " + AllTrim(cStConv) + " inválido.")
endif

// Verifica se a forma de pagamento da empresa é válido
cForPgt := oJson["EMPRESA"]:GetJsonText("formaPagamento")
if cTipCon == "1"  // Estágio
	if Empty(cForPgt) .or. !(cForPgt $ "12")
		Return("Forma de pagamento da empresa " + AllTrim(cForPgt) + " inválido.")
	endif
else  // Aprendiz
	if Empty(cForPgt)
		Return("Forma de pagamento da empresa " + AllTrim(cForPgt) + " inválido.")
	endif
endif

// Verifica se enviou o estado do endereço da empresa
cUfEmp := oJson["EMPRESA"]["ENDERECO"]:GetJsonText("uf")
if Empty(cUfEmp)
	Return("O estado do endereço da empresa e obrigatório.")
endif

// Verifica se enviou o código do município do endereço da empresa
cCodMunEmp := oJson["EMPRESA"]["ENDERECO"]:GetJsonText("codigoMunicipioIBGE")
if Empty(cCodMunEmp)
	Return("O código do municipio do endereço da empresa e obrigatório.")
endif

// Verifica se o estado e código do município do endereço da empresa são válidos
if !CC2->(DbSeek(xFilial("CC2")+cUfEmp+Right(cCodMunEmp,5)))
	Return("O estado " + AllTrim(cUfEmp) + " e/ou código do município " + AllTrim(cCodMunEmp) + " do endereço da empresa inválido.")
endif
cCidEmp := AllTrim(CC2->CC2_MUN)

// Verifica se enviou os representantes
if Len(oJson["EMPRESA"]["representantes"]) <= 0
	Return("O representante legal e administrativo são obrigatórios.")
else
	for nI = 1 to Len(oJson["EMPRESA"]["representantes"])

		if oJson["EMPRESA"]["representantes"][nI]:GetJsonText("tipo") $ "12"
			if Empty(oJson["EMPRESA"]["representantes"][nI]:GetJsonText("nome"))
				Return("O nome do representante é obrigatório.")
			endif
		endif

		if Empty(oJson["EMPRESA"]["representantes"][nI]:GetJsonText("cargo"))
			Return("O cargo do representante é obrigatório.")
		endif

		if Empty(oJson["EMPRESA"]["representantes"][nI]:GetJsonText("email"))
			Return("O email do representante é obrigatório.")
		endif

	next
endif

Return("")

/*/{Protheus.doc} GravaCon
Realiza a gravação do contrato
@author danilo.grodzicki
@since 09/07/2020
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function GravaCon(oJson)

Local nCnta
Local nRepres
Local nContato

cPrgApe := DecodeUTF8(oJson["EMPRESA"]:GetJsonText("programaAprendizagem"))
cTipEmp := oJson["EMPRESA"]:GetJsonText("tipoEmpresa")
cNome   := DecodeUTF8(oJson["EMPRESA"]:GetJsonText("razaoSocial"))
cNReduz := DecodeUTF8(oJson["EMPRESA"]:GetJsonText("nomeFantasia"))
cNumDoc := oJson["EMPRESA"]:GetJsonText("documento")
cStConv := oJson["EMPRESA"]:GetJsonText("sitcontrato")
cStEmpr := DecodeUTF8(oJson["EMPRESA"]:GetJsonText("sitempresa"))
cCepEmp := oJson["EMPRESA"]["ENDERECO"]:GetJsonText("cep")
cLogEmp := oJson["EMPRESA"]["ENDERECO"]:GetJsonText("logradouro")
cEndEmp := DecodeUTF8(oJson["EMPRESA"]["ENDERECO"]:GetJsonText("endereco"))
cNumEmp := oJson["EMPRESA"]["ENDERECO"]:GetJsonText("numero")
cComEmp := DecodeUTF8(oJson["EMPRESA"]["ENDERECO"]:GetJsonText("complemento"))
cBaiEmp := DecodeUTF8(oJson["EMPRESA"]["ENDERECO"]:GetJsonText("bairro"))
cIdCoEn := oJson["EMPRESA"]["CONSULTOR"]:GetJsonText("id")
cNoCoEn := DecodeUTF8(oJson["EMPRESA"]["CONSULTOR"]:GetJsonText("nome"))
cCaCoEn := oJson["EMPRESA"]["CONSULTOR"]:GetJsonText("idCarteira")
cDeCoEn := DecodeUTF8(oJson["EMPRESA"]["CONSULTOR"]:GetJsonText("dsCarteira"))

cRepres:= ' {'
cRepres+= '    "representantes":['

nRepres := LEN(oJson["EMPRESA"]["representantes"])

For nCnta:= 1 TO nRepres

	cRepres+= '       {'
	cRepres+= '          "tipo":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("tipo")	+'",'
	cRepres+= '          "nome":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("nome")	+'",'
	cRepres+= '          "cargo":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("cargo")	+'",'
	cRepres+= '          "cpf":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("cpf")	+'",'
	cRepres+= '          "tpfone":"'+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("tpfone")+'",'
	cRepres+= '          "ddd":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("ddd")	+'",'
	cRepres+= '          "fone":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("fone")	+'",'
	cRepres+= '          "ramal":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("ramal")	+'",'
	cRepres+= '          "email":"'	+oJson["EMPRESA"]["representantes"][nCnta]:GetJsonText("email")	+'"'

	if nCnta < nRepres
		cRepres+= '       },'
	else
		cRepres+= '       }'
	endif	
	
Next

cRepres+= '    ]'
cRepres+= ' }'

cContato:= ' {'
cContato+= '    "contatos":['

nContato := LEN(oJson["EMPRESA"]["contatos"])

For nCnta:= 1 TO nContato

	cContato+= '       {'
	cContato+= '          "nome":"'			+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("nome")		+'",'
	cContato+= '          "tipo":"'			+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("tipo")		+'",'
	cContato+= '          "cargo":"'		+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("cargo")		+'",'
	cContato+= '          "cpf":"'			+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("cpf")			+'",'
	cContato+= '          "tpfone":"'		+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("tpfone")		+'",'
	cContato+= '          "ddd":"'			+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("ddd")			+'",'
	cContato+= '          "fone":"'			+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("fone")		+'",'
	cContato+= '          "ramal":"'		+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("ramal")		+'",'
	cContato+= '          "email":"'		+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("email")		+'",'
	cContato+= '          "status":"'		+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("status")		+'",'
	cContato+= '          "segmento":"'		+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("segmento")	+'",'
	cContato+= '          "departamento":"'	+oJson["EMPRESA"]["contatos"][nCnta]:GetJsonText("departamento")+'"'

	if nCnta < nContato
		cContato+= '       },'
	else
		cContato+= '       }'
	endif	
	
Next

cContato+= '    ]'
cContato+= ' }'

Begin Transaction
	
	Sleep(500)

	ZC0->(DbSetOrder(01))
	if ZC0->(DbSeek(xFilial("ZC0")+Padr(AllTrim(cIdEmp),TamSX3("ZC0_CODIGO")[1]," ")))
		RecLock("ZC0",.F.)
	else
		RecLock("ZC0",.T.)
	endif	
		ZC0->ZC0_FILIAL := xFilial("ZC0")
		ZC0->ZC0_CODIGO := cIdEmp
		ZC0->ZC0_TIPCON := cTipCon
		ZC0->ZC0_TIPAPR := cTipApe
		ZC0->ZC0_PRGAPE := cPrgApe
		ZC0->ZC0_TIPEMP := cTipEmp
		ZC0->ZC0_NOME   := cNome
		ZC0->ZC0_NREDUZ := iif(Empty(cNReduz),cNome,cNReduz)
		ZC0->ZC0_NUMDOC := cNumDoc
		ZC0->ZC0_STCONV := cStConv
		ZC0->ZC0_STEMPR := cStEmpr
		ZC0->ZC0_FORPGT := cForPgt
		ZC0->ZC0_CEPEMP := cCepEmp
		ZC0->ZC0_LOGEMP := cLogEmp
		ZC0->ZC0_ENDEMP := cEndEmp
		ZC0->ZC0_NUMEMP := cNumEmp
		ZC0->ZC0_COMEMP := cComEmp
		ZC0->ZC0_BAIEMP := cBaiEmp
		ZC0->ZC0_CMUNEM := cCodMunEmp
		ZC0->ZC0_CIDEMP := cCidEmp
		ZC0->ZC0_ESTEMP := cUfEmp
		ZC0->ZC0_REPR	:= cRepres
		ZC0->ZC0_CONTAT	:= cContato
		ZC0->ZC0_DTINTE := Date()
		ZC0->ZC0_HRINTE := Time()
		ZC0->ZC0_JSON   := cJson
		ZC0->ZC0_IDCOEN := cIdCoEn
		ZC0->ZC0_NOCOEN := cNoCoEn
		ZC0->ZC0_CACOEN := cCaCoEn
		ZC0->ZC0_DECOEN := cDeCoEn
	ZC0->(MsUnLock())
	
End Transaction

Return Nil