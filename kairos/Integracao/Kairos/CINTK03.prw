#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK03
Serviço de integração das configurações de Faturamento
@author carlos.henrique
@since 19/03/2019
@version undefined
@type function
/*/
USER FUNCTION CINTK03(nRecno) 

Local cErro

Local cMsgOK := ""

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cIdFatu    := space(015)
Private cIdCont    := space(015)
Private cSitCon    := space(001)
Private cConUni    := space(001)
Private cTipCon    := space(001)
Private cTipEmi    := space(001)
Private cPerFat    := space(001)
Private cReajCi    := space(001)
Private cRepEmp    := space(001)
Private cNome      := space(150)
Private cNomRep    := space(150)
Private cDocRep    := space(011)
Private cAreRep    := space(100)
Private cCarRep    := space(100)
Private cMaiRep    := space(100)
Private cDddRep    := space(002)
Private cTelRep    := space(009)
Private cRamRep    := space(009)
Private cPerCon    := space(003)
Private nVlrCi     := 0
Private nVlrCon    := 0
Private cMesBas    := space(002)
Private cCompet    := space(001)
Private cDesInd    := space(100)
Private nCiaPre    := 0
Private cDiaEmi    := space(002)
Private cCodBco    := space(003)
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""
Private lErroTenta := .F.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK03] INICIO - Serviço de integração das configurações de Faturamento - RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

IF !EMPTY(ZCQ->ZCQ_JSON)

	oJson:= JsonObject():new()
	oJson:fromJson(ZCQ->ZCQ_JSON)   

	cJson := ZCQ->ZCQ_JSON

	// if  At("CONFIGURACAO",cJson) == 0
	// 	RECLOCK("ZCQ",.F.)
	// 		ZCQ->ZCQ_STATUS := "1" 	
	// 		ZCQ->ZCQ_CODE   := "404"  // Erro
	// 		ZCQ->ZCQ_MSG    := "Payload inválido"
	// 	MSUNLOCK()	
	// 	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK03] FIM - Serviço de integração das configurações de Faturamento - RECNO:" + CVALTOCHAR(nRecno))
	// 	Return
	// endif

	//Avalia o campo operação ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"I")
			if Empty(cErro)
				GravaZc4(oJson)
				cMsgOK := "Configurações de Faturamento cadastrada com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"A")
			if Empty(cErro)
				// Realiza a alteração do contrato e local de contrato
				GravaZc4(oJson)
				cMsgOK := "Configurações de Faturamento alteradas com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"E")

			if Empty(cErro)

				// Desativa o registro da tabela ZC4
				Begin Transaction
					RecLock("ZC4",.F.)
						ZC4->ZC4_STATUS := "2"
					ZC4->(MsUnLock())
				End Transaction

				cMsgOK := "Configurações de Faturamento desativadas com sucesso."

			endif

	ENDCASE

	FreeObj(oJson)	 
ELSE
	cErro := "JSON NÃO INFORMADO"
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

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK03] FIM - Serviço de integração das configurações de Faturamento - RECNO:" + CVALTOCHAR(nRecno))

return

/*/{Protheus.doc} CONFIGFAT
Serviço de integração das configurações de Faturamento
@author carlos.henrique
@since 01/03/2019
@version undefined
@type class
/*/
WSRESTFUL CONFIGFAT DESCRIPTION "Serviço de integração das configurações de Faturamento" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza o cadastro das configurações de Faturamento";
	WSSYNTAX "/CONFIGFAT"
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a atualizacao das configurações de Faturamento";
	WSSYNTAX "/CONFIGFAT"
	WSMETHOD DELETE; 
	DESCRIPTION "Desativa as configurações de Faturamento";
	WSSYNTAX "/CONFIGFAT"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta das configurações de Faturamento";
	WSSYNTAX "/CONFIGFAT"
END WSRESTFUL
 
/*/{Protheus.doc} POST
Realiza o cadastro das configurações de Faturamento
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD POST WSSERVICE CONFIGFAT

Local cErro

Local aRet := {}

Private oRet      := Nil
Private oJson     := Nil
Private cJson     := Nil
Private cIdFatu   := space(015)
Private cIdCont   := space(015)
Private cSitCon   := space(001)
Private cConUni   := space(001)
//Private cUnCIEE   := space(015)
//Private cCentra   := space(001)
Private cTipCon   := space(001)
Private cTipEmi   := space(001)
//Private cValFat   := space(001)
Private cPerFat   := space(001)
Private cReajCi   := space(001)
Private cRepEmp   := space(001)
Private cNome     := space(150)
Private cNomRep   := space(150)
Private cDocRep   := space(011)
Private cAreRep   := space(100)
Private cCarRep   := space(100)
Private cMaiRep   := space(100)
Private cDddRep   := space(002)
Private cTelRep   := space(009)
Private cRamRep   := space(009)
Private cPerCon   := space(003)
Private nVlrCi    := 0
Private nVlrCon   := 0
Private cMesBas   := space(002)
Private cCompet   := space(001)
Private cDesInd   := space(100)
Private nCiaPre   := 0
Private cDiaEmi   := space(002)
Private cCodBco   := space(003)
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cCodEXc   := space(003)
Private nVlrEXc   := 0

DbSelectArea("ZC0")
ZC0->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("SA6")
SA6->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"I")
if !Empty(cErro)
	U_GrvLogKa("CINTK03", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONFIGFAT",oJson:toJSON(),"POST")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK03", "DW3POST", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a gravação na tabela ZC4
GravaZc4(oJson)

U_GrvLogKa("CINTK03", "POST", "1", "Integracao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integracao realizada com sucesso")

/*/{Protheus.doc} PUT
Realiza a atualizacao das configurações de Faturamento
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD PUT WSSERVICE CONFIGFAT

Local cErro

Local aRet := {}

Private oRet      := Nil
Private oJson     := Nil
Private cJson     := Nil
Private cIdFatu   := space(015)
Private cIdCont   := space(015)
Private cSitCon   := space(001)
Private cConUni   := space(001)
//Private cUnCIEE   := space(015)
//Private cCentra   := space(001)
Private cTipCon   := space(001)
Private cTipEmi   := space(001)
//Private cValFat   := space(001)
Private cPerFat   := space(001)
Private cReajCi   := space(001)
Private cRepEmp   := space(001)
Private cNome     := space(150)
Private cNomRep   := space(150)
Private cDocRep   := space(011)
Private cAreRep   := space(100)
Private cCarRep   := space(100)
Private cMaiRep   := space(100)
Private cDddRep   := space(002)
Private cTelRep   := space(009)
Private cRamRep   := space(009)
Private cPerCon   := space(003)
Private nVlrCi    := 0
Private nVlrCon   := 0
Private cMesBas   := space(002)
Private cCompet   := space(001)
Private cDesInd   := space(100)
Private nCiaPre   := 0
Private cDiaEmi   := space(002)
Private cCodBco   := space(003)
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cCodEXc   := space(003)
Private nVlrEXc   := 0

DbSelectArea("SA6")
SA6->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"A")
if !Empty(cErro)
	U_GrvLogKa("CINTK03", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONFIGFAT",oJson:toJSON(),"PUT")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK03", "DW3PUT", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a gravação na tabela ZC4
GravaZc4(oJson)

U_GrvLogKa("CINTK03", "PUT", "1", "Atualização realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Atualização realizada com sucesso")

/*/{Protheus.doc} DELETE
Realiza a desativação das configurações de Faturamento
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD DELETE WSSERVICE CONFIGFAT

Local cErro

Local aRet  := {}
Local oJson := Nil

Private cJson     := Nil
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"E")
if !Empty(cErro)
	U_GrvLogKa("CINTK03", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONFIGFAT",oJson:toJSON(),"DELETE")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK03", "DW3DELETE", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Desativa o registro da tabela ZC4
Begin Transaction
	RecLock("ZC4",.F.)
	ZC4->ZC4_STATUS := "2"
	ZC4->(MsUnLock())
End Transaction

U_GrvLogKa("CINTK03", "DELETE", "1", "Desativação realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Desativação realizada com sucesso")

/*/{Protheus.doc} GET
Realiza a consulta das configurações de Faturamento
@author Danilo José Grodzicki
@since 21/09/2019
@/version undefined

@type function
/*/

WSMETHOD GET WSSERVICE CONFIGFAT

Local cErro

Local oJson := Nil
Local cJson := ""

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"C")
if !Empty(cErro)
	U_GrvLogKa("CINTK03", "GET", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

cJson := '{'
cJson += '	"CONFIGURACAO": {'
cJson += '		"id": "' + EncodeUTF8(AllTrim(ZC4->ZC4_IDFATU), "cp1252") + '",'
cJson += '		"nome": "' + EncodeUTF8(AllTrim(ZC4->ZC4_NOME), "cp1252") + '",'
cJson += '		"sitConfiguracao": "' + EncodeUTF8(AllTrim(ZC4->ZC4_SITCON), "cp1252") + '",'
cJson += '		"idContrato": "' + EncodeUTF8(AllTrim(ZC4->ZC4_IDCONT), "cp1252") + '",'
cJson += '		"ContratoUnico": "' + EncodeUTF8(AllTrim(ZC4->ZC4_CONUNI), "cp1252") + '",'
//cJson += '		"Idunidade": "' + EncodeUTF8(AllTrim(ZC4->ZC4_UNCIEE), "cp1252") + '",'
//cJson += '		"centralizar": "' + EncodeUTF8(AllTrim(ZC4->ZC4_CENTRA), "cp1252") + '",'
cJson += '		"REPRESENTANTE": {'
cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC4->ZC4_NOMREP), "cp1252") + '",'
cJson += '			"documento": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DOCREP), "cp1252") + '",'
cJson += '			"areaSetor": "' + EncodeUTF8(AllTrim(ZC4->ZC4_AREREP), "cp1252") + '",'
cJson += '			"cargo": "' + EncodeUTF8(AllTrim(ZC4->ZC4_CARREP), "cp1252") + '",'
cJson += '			"email": "' + EncodeUTF8(AllTrim(ZC4->ZC4_MAIREP), "cp1252") + '",'
cJson += '			"ddd": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DDDREP), "cp1252") + '",'
cJson += '			"telefone": "' + EncodeUTF8(AllTrim(ZC4->ZC4_TELREP), "cp1252") + '",'
cJson += '			"ramal": "' + EncodeUTF8(AllTrim(ZC4->ZC4_RAMREP), "cp1252") + '"'
cJson += '		},'
cJson += '		"CONTRIBUICAO": {'
cJson += '			"tipo": "' + EncodeUTF8(AllTrim(ZC4->ZC4_TIPCON), "cp1252") + '",'
cJson += '			"percentual": "' + EncodeUTF8(AllTrim(ZC4->ZC4_PERCON), "cp1252") + '",'
cJson += '			"valorCIEstudante": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_VLRCI,14,2)), "cp1252") + '",'

oFaixas:= JsonObject():new()
oFaixas:fromJson(AllTrim(ZC4->ZC4_FAIXAS))
cFaixas:= oFaixas:TOJSON()
cFaixas:= RIGHT(cFaixas,LEN(cFaixas)-1)
cFaixas:= LEFT(cFaixas,LEN(cFaixas)-1)

cJson += cFaixas+","

cJson += '			"valorContribuicao": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_VLRCON,14,2)), "cp1252") + '",'
cJson += '			"mesbase": "' + EncodeUTF8(AllTrim(ZC4->ZC4_MESBAS), "cp1252") + '",'
cJson += '			"competencia": "' + EncodeUTF8(AllTrim(ZC4->ZC4_COMPET), "cp1252") + '",'
cJson += '			"Indice": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DESIND), "cp1252") + '",'
cJson += '			"ContribuicaoInicial": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_CIAPRE,14,2)), "cp1252") + '",'
cJson += '			"EMISSAO": {'
cJson += '				"tipo": "' + EncodeUTF8(AllTrim(ZC4->ZC4_TIPEMI), "cp1252") + '",'
cJson += '				"dia": "' + EncodeUTF8(AllTrim(ZC4->ZC4_DIAEMI), "cp1252") + '"'
cJson += '			},'
//cJson += '			"validaFaturamento": "' + EncodeUTF8(AllTrim(ZC4->ZC4_VALFAT), "cp1252") + '",'
cJson += '			"permutaFaturamento": "' + EncodeUTF8(AllTrim(ZC4->ZC4_PERFAT), "cp1252") + '",'
cJson += '			"bancoFaturamento": "' + EncodeUTF8(AllTrim(ZC4->ZC4_CODBCO), "cp1252") + '",'
cJson += '			"bancoExcedente": "' + EncodeUTF8(AllTrim(ZC4->ZC4_BCOEXC), "cp1252") + '",'
cJson += '			"valorExcedente": "' + EncodeUTF8(AllTrim(Str(ZC4->ZC4_VLREXC,14,2)), "cp1252") + '",'
cJson += '			"reajusteanual": "' + EncodeUTF8(AllTrim(ZC4->ZC4_REAJCI), "cp1252") + '",'
cJson += '			"repasseEmpresa": "' + EncodeUTF8(AllTrim(ZC4->ZC4_REPEMP), "cp1252") + '"'
cJson += '		}'
cJson += '	}'
cJson += '}'

::SetResponse(cJson)

Return .T.

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author Danilo José Grodzicki
@since 22/09/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

// Verifica se enviou o ID da configuração do faturamento
cIdFatu := oJson["CONFIGURACAO"]:GetJsonText("id")
if Empty(cIdFatu)
	Return("O ID da configuração de faturamento é obrigátorio.")
endif

// Verifica se enviou o ID do contrato
cIdCont := oJson["CONFIGURACAO"]:GetJsonText("idContrato")
if Empty(cIdCont)
	Return("O ID do contrato é obrigatório.")
endif	

if cTipo == "E" .or.  cTipo == "C"   // Exclusão ou Consuta

	// Verifica se o ID de Faturamento, ID do local de contrato e o ID da configuração do faturamento está cadastrado
	if !ZC4->(DbSeek(xFilial("ZC4") + Padr(AllTrim(cIdFatu),TamSX3("ZC4_IDFATU")[1]," ") + Padr(AllTrim(cIdCont),TamSX3("ZC4_IDCONT")[1]," ")))
		Return("O ID do faturamento " + AllTrim(cIdFatu) + " não existe.")
	else
		Return("")
	endif
	
endif

// Verifica se enviou o banco do faturamento
if Empty(AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoFaturamento")))
	Return("O banco de faturamento é obrigatorio.")
endif

if !SA6->(DbSeek(xFilial("SA6")+StrZero(Val(AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoFaturamento"))),3)))
	Return("Banco de faturamento inválido: " + AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoFaturamento")))
endif

// Verifica se enviou o banco excedente
//if Empty(AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoExcedente")))
//	Return("O banco de excedente é obrigatorio.")
//endif

if !Empty(AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoExcedente")))
	if !SA6->(DbSeek(xFilial("SA6")+StrZero(Val(AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoExcedente"))),3)))
		Return("Banco de excedente inválido: " + AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoExcedente")))
	endif
endif
	
if !Empty(AllTrim(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoExcedente")))
	if Val(oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("valorExcedente")) <= 0
		Return("Valor excedente " + oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("valorExcedente") + " inválido.")
	endif
endif

// Verifica se o contrato está cadastrado
if !ZC0->(DbSeek(xFilial("ZC0") + Padr(AllTrim(cIdCont),TamSX3("ZC1_CODIGO")[1]," ")))
	lErroTenta := .T.
	Return("O contrato " + AllTrim(cIdCont) + " não existe.")
endif	

// Verifica se a situação de configuração é válida
cSitCon := oJson["CONFIGURACAO"]:GetJsonText("sitConfiguracao")
if Empty(cSitCon) .or. !(cSitCon $ "01")
	Return("Situação de configuração " + AllTrim(cSitCon) + " inválido.")
endif

// Verifica se o contrato único é válido
cConUni := oJson["CONFIGURACAO"]:GetJsonText("ContratoUnico")
if Empty(cConUni) .or. !(cConUni $ "SN")
	Return("Contrato único " + AllTrim(cConUni) + " inválido.")
endif

// Verifica se o id da inidade CIEE é válido
//cUnCIEE := oJson["CONFIGURACAO"]:GetJsonText("Idunidade")
//if Empty(cUnCIEE) 
//	Return("Unidade CIEE (Idunidade) é obrigatória.")
//endif

// Verifica se a centralização financeira é válide
//cCentra := oJson["CONFIGURACAO"]:GetJsonText("centralizar")
//if Empty(cCentra) .or. !(cCentra $ "SN")
//	Return("Centralização financeira " + AllTrim(cCentra) + " inválida.")
//endif

// Verifica se o tipo de contribuição é válido
cTipCon := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("tipo")
if Empty(cTipCon) .or. !(cTipCon $ "123")
	Return("Tipo de contribuição " + AllTrim(cTipCon) + " inválido.")
endif

// Verifica se o tipo emissão é válido
cTipEmi := oJson["CONFIGURACAO"]["CONTRIBUICAO"]["EMISSAO"]:GetJsonText("tipo")
if Empty(cTipEmi) .or. !(cTipEmi $ "124")
	Return("Tipo emissão " + AllTrim(cTipEmi) + " inválido.")
endif

// Verifica se validar faturamento é válido
//cValFat := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("validaFaturamento")
//if Empty(cValFat) .or. !(cValFat $ "SN")
//	Return("Validar faturamento " + AllTrim(cValFat) + " inválido.")
//endif

// Verifica se permuta de faturamento é válido
cPerFat := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("permutaFaturamento")
if Empty(cPerFat) .or. !(cPerFat $ "SN")
	Return("Permuta de faturamento " + AllTrim(cPerFat) + " inválido.")
endif

// Verifica se realiza reajuste de CI anual é válido
cReajCi := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("reajusteanual")
if Empty(cReajCi) .or. !(cReajCi $ "SN")
	Return("Realiza reajuste de CI anual " + AllTrim(cReajCi) + " inválido.")
endif

// Verifica se repasse para empresa é válido
cRepEmp := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("repasseEmpresa")
if Empty(cRepEmp) .or. !(cRepEmp $ "SN")
	Return("Repasse para empresa " + AllTrim(cRepEmp) + " inválido.")
endif

Return("")

/*/{Protheus.doc} GravaZc4
Realiza a gravação na tabela ZC4
@author Danilo José Grodzicki
@since 22/09/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function GravaZc4(oJson)

Local nCnta

cNome   := DecodeUTF8(oJson["CONFIGURACAO"]:GetJsonText("nome"))
cNomRep := DecodeUTF8(oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("nome"))
cDocRep := oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("documento")
cAreRep := DecodeUTF8(oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("areaSetor"))
cCarRep := DecodeUTF8(oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("cargo"))
cMaiRep := DecodeUTF8(oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("email"))
cDddRep := oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("ddd")
cTelRep := oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("telefone")
cRamRep := oJson["CONFIGURACAO"]["REPRESENTANTE"]:GetJsonText("ramal")
cPerCon := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("percentual")
nVlrCi  := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("valorCIEstudante")

cFaixas:= ' {'
cFaixas+= '    "FAIXAS":['

nTFaixas := LEN(oJson["CONFIGURACAO"]["CONTRIBUICAO"]["FAIXAS"])

For nCnta:= 1 TO nTFaixas

	cFaixas+= '       {'
	cFaixas+= '          "minimo":'+oJson["CONFIGURACAO"]["CONTRIBUICAO"]["FAIXAS"][nCnta]:GetJsonText("minimo")+','
	cFaixas+= '          "maximo":'+oJson["CONFIGURACAO"]["CONTRIBUICAO"]["FAIXAS"][nCnta]:GetJsonText("maximo")+','
	cFaixas+= '          "valorCI":'+oJson["CONFIGURACAO"]["CONTRIBUICAO"]["FAIXAS"][nCnta]:GetJsonText("valorCI")
	
	if nCnta < nTFaixas
		cFaixas+= '       },'
	else
		cFaixas+= '       }'
	endif	
	
Next

cFaixas+= '    ]'
cFaixas+= ' }'

nVlrCon := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("valorContribuicao")
cMesBas := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("mesbase")
cCompet := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("competencia")
cDesInd := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("Indice")
nCiaPre := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("ContribuicaoInicial")
cDiaEmi := oJson["CONFIGURACAO"]["CONTRIBUICAO"]["EMISSAO"]:GetJsonText("dia")
cCodBco := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoFaturamento")
cCodEXc := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("bancoExcedente")
nVlrEXc := oJson["CONFIGURACAO"]["CONTRIBUICAO"]:GetJsonText("valorExcedente")

Begin Transaction

	Sleep(500)

	ZC4->(DbSetOrder(01))
	if ZC4->(DbSeek(xFilial("ZC4") + Padr(AllTrim(cIdFatu),TamSX3("ZC4_IDFATU")[1]," ") + Padr(AllTrim(cIdCont),TamSX3("ZC4_IDCONT")[1]," ")))
		RecLock("ZC4",.F.)
	else
		RecLock("ZC4",.T.)
	endif
		ZC4->ZC4_FILIAL := xFilial("ZC4")
		ZC4->ZC4_IDFATU := cIdFatu
		ZC4->ZC4_NOME   := cNome
		ZC4->ZC4_SITCON := cSitCon
		ZC4->ZC4_IDCONT := cIdCont
		ZC4->ZC4_CONUNI := cConUni
//		ZC4->ZC4_UNCIEE := cUnCIEE
//		ZC4->ZC4_CENTRA := cCentra 
		ZC4->ZC4_NOMREP := cNomRep
		ZC4->ZC4_DOCREP := cDocRep
		ZC4->ZC4_AREREP := cAreRep
		ZC4->ZC4_CARREP := cCarRep
		ZC4->ZC4_MAIREP := cMaiRep
		ZC4->ZC4_DDDREP := cDddRep
		ZC4->ZC4_TELREP := cTelRep
		ZC4->ZC4_RAMREP := cRamRep
		ZC4->ZC4_TIPCON := cTipCon
		ZC4->ZC4_PERCON := cPerCon
		ZC4->ZC4_VLRCI  := Val(nVlrCi) 
		ZC4->ZC4_FAIXAS := cFaixas
		ZC4->ZC4_VLRCON := Val(nVlrCon)
		ZC4->ZC4_MESBAS := cMesBas
		ZC4->ZC4_COMPET := cCompet
		ZC4->ZC4_DESIND := cDesInd
		ZC4->ZC4_CIAPRE := Val(nCiaPre)
		ZC4->ZC4_TIPEMI := cTipEmi
		ZC4->ZC4_DIAEMI := cDiaEmi
//		ZC4->ZC4_VALFAT := cValFat
		ZC4->ZC4_PERFAT := cPerFat
		ZC4->ZC4_CODBCO := cCodBco
		ZC4->ZC4_BCOEXC := cCodEXc
		ZC4->ZC4_VLREXC := Val(nVlrEXc)
		ZC4->ZC4_REAJCI := cReajCi
		ZC4->ZC4_REPEMP := cRepEmp
		ZC4->ZC4_DTINTE := Date()
		ZC4->ZC4_HRINTE := Time()
		ZC4->ZC4_JSON   := cJson
		if cSitCon == "0"  // Inativo
			ZC4->ZC4_STATUS := "2"
		elseif cSitCon == "1"  // Ativo
			ZC4->ZC4_STATUS := "1"
		endif
	ZC4->(MsUnLock())
End Transaction

Return Nil
