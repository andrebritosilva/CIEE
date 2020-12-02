#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK01
Serviço de integração do contrato e local de contrato
@author carlos.henrique
@since 19/03/2019
@version undefined
@type function
/*/
USER FUNCTION CINTK01(nRecno)

Local cErro

Local cMsgOK  := ""
Local nExclui := 0

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cNome      := space(150)
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfEmp     := space(002)
Private cUfCont    := space(002)
Private cTipCon    := space(001)
Private cTipApe    := space(001)
Private cForPgt    := space(001)
Private cCidEmp    := space(050)
Private cCidCon    := space(050)
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
Private cRazSoc    := space(150)
Private cNomFan    := space(050)
Private cDocLoc    := space(014)
Private cInsEst    := space(018)
Private cInsNum    := space(018)
Private cCepLoc    := space(008)
Private cLogLoc    := space(150)
Private cEndLoc    := space(150)
Private cNumLoc    := space(010)
Private cComLoc    := space(050)
Private cBaiLoc    := space(050)
Private cCodMunEmp := space(050)
Private cCodMunCon := space(050)
Private cIdCoLo    := space(015)
Private cNoCoLo    := space(150)
Private cCaCoLo    := space(015)
Private cDeCoLo    := space(150)
Private cIdCoEn    := space(015)
Private cNoCoEn    := space(150)
Private cCaCoEn    := space(015)
Private cDeCoEn    := space(150)

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK01] INICIO - Serviço de integração do contrato e local de contrato - RECNO:" + CVALTOCHAR(nRecno))

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

	// if  At("EMPRESA",cJson) == 0
	// 	RECLOCK("ZCQ",.F.)
	// 		ZCQ->ZCQ_STATUS := "1" 	
	// 		ZCQ->ZCQ_CODE   := "404"  // Erro
	// 		ZCQ->ZCQ_MSG    := "Payload inválido"
	// 	MSUNLOCK()	
	// 	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK01] FIM - Serviço de integração do contrato e local de contrato - RECNO:" + CVALTOCHAR(nRecno))
	// 	Return
	// endif

	//Avalia o campo operação ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"I")
			if Empty(cErro)
				GravaCon(oJson)
				cMsgOK := "Cotrato/Local de contrato cadastrado com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"A")
			if Empty(cErro)
				// Realiza a alteração do contrato e local de contrato
				GravaCon(oJson)
				cMsgOK := "Cotrato/Local de contrato alterado com sucesso."
			endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"E")

			if Empty(cErro)

				Begin Transaction
					
					if RecLock("ZC0",.F.)
						ZC0->(DbDelete())
						ZC0->(MsUnLock())
						nExclui ++
					endif

					if RecLock("ZC1",.F.)
						ZC1->(DbDelete())
						ZC1->(MsUnLock())
						nExclui ++
					endif

				End Transaction

				if nExclui==2
					cMsgOK := "Cotrato/Local de contrato excluído com sucesso."
				else
					cErro := "Erro ao tentar excluir Cotrato/Local de contrato."
				endif

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

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK01] FIM - Serviço de integração do contrato e local de contrato - RECNO:" + CVALTOCHAR(nRecno))

RETURN

/*/{Protheus.doc} CONTRATO
Serviço de integração do contrato e local de contrato
@author carlos.henrique
@since 01/03/2019
@version undefined
@type class
/*/
WSRESTFUL CONTRATO DESCRIPTION "Serviço de integração do contrato e local de contrato" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza o cadastro do contrato e local de contrato";
	WSSYNTAX "/CONTRATO
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a atualização do contrato e local de contrato";
	WSSYNTAX "/CONTRATO"
	WSMETHOD DELETE; 
	DESCRIPTION "Realiza a exclusão do contrato e local de contrato";
	WSSYNTAX "/CONTRATO"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta do contrato e local de contrato";
	WSSYNTAX "/CONTRATO"
END WSRESTFUL

/*/{Protheus.doc} POST
Realiza o cadastro do contrato e local de contrato
@author carlos.henrique
@since 01/03/2019
@/version undefined

@type function
/*/
WSMETHOD POST WSSERVICE CONTRATO

Local cErro

Local aRet := {}

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cNome      := space(150)
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfEmp     := space(002)
Private cUfCont    := space(002)
Private cTipCon    := space(001)
Private cTipApe    := space(001)
Private cForPgt    := space(001)
Private cCidEmp    := space(050)
Private cCidCon    := space(050)
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
Private cRazSoc    := space(150)
Private cNomFan    := space(050)
Private cDocLoc    := space(014)
Private cInsEst    := space(018)
Private cInsNum    := space(018)
Private cCepLoc    := space(008)
Private cLogLoc    := space(150)
Private cEndLoc    := space(150)
Private cNumLoc    := space(010)
Private cComLoc    := space(050)
Private cBaiLoc    := space(050)
Private cCodMunEmp := space(050)
Private cCodMunCon := space(050)
Private cIdCoLo    := space(015)
Private cNoCoLo    := space(150)
Private cCaCoLo    := space(015)
Private cDeCoLo    := space(150)
Private cIdCoEn    := space(015)
Private cNoCoEn    := space(150)
Private cCaCoEn    := space(015)
Private cDeCoEn    := space(150)
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""

dbSelectArea("ZC0")
ZC0->(dbSetOrder(1))

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
	U_GrvLogKa("CINTK01", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

//Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONTRATO",oJson:toJSON(),"POST")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK01", "DW3POST", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a gravação do contrato e local de contrato
GravaCon(oJson)

U_GrvLogKa("CINTK01", "POST", "1", "Integração realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integração realizada com sucesso")

/*/{Protheus.doc} PUT
Realiza a atualizacao do contrato e local de contrato
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD PUT WSSERVICE CONTRATO

Local cErro

Local aRet := {}

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private cNome      := space(150)
Private cIdEmp     := space(015)
Private cIdLoc     := space(015)
Private cUfEmp     := space(002)
Private cUfCont    := space(002)
Private cTipCon    := space(001)
Private cTipApe    := space(001)
Private cForPgt    := space(001)
Private cCidEmp    := space(050)
Private cCidCon    := space(050)
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
Private cRazSoc    := space(150)
Private cNomFan    := space(050)
Private cDocLoc    := space(014)
Private cInsEst    := space(018)
Private cInsNum    := space(018)
Private cCepLoc    := space(008)
Private cLogLoc    := space(150)
Private cEndLoc    := space(150)
Private cNumLoc    := space(010)
Private cComLoc    := space(050)
Private cBaiLoc    := space(050)
Private cCodMunEmp := space(050)
Private cCodMunCon := space(050)
Private cIdCoLo    := space(015)
Private cNoCoLo    := space(150)
Private cCaCoLo    := space(015)
Private cDeCoLo    := space(150)
Private cIdCoEn    := space(015)
Private cNoCoEn    := space(150)
Private cCaCoEn    := space(015)
Private cDeCoEn    := space(150)
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
	U_GrvLogKa("CINTK01", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

// Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONTRATO",oJson:toJSON(),"PUT")
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK01", "DW3PUT", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

// Realiza a gravação do contrato e local de contrato
GravaCon(oJson)

U_GrvLogKa("CINTK01", "PUT", "1", "Atualização realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Atualização realizada com sucesso")

/*/{Protheus.doc} DELETE
Realiza a exclusão do contrato e local de contrato
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD DELETE WSSERVICE CONTRATO

Local cErro

Local aRet  := {}
Local oJson := Nil

Private cJson      := Nil
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
	U_GrvLogKa("CINTK01", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro,1)
endif

// Envia os dados para o DW3
cHrIniDw3 := Time()
aRet      := U_CINTD01("CONTRATO",oJson:toJSON(),"DELETE") 
if Len(aRet) > 0
	if !aRet[1][1]
		cHrFimDw3 := Time()
		U_GrvLogKa("CINTK01", "DW3DELETE", "2", aRet[1][2], cJson, oJson)
		Return U_RESTERRO(Self,aRet[1][2],2)
	endif
endif
cHrFimDw3 := Time()

Begin Transaction
	
 	if RecLock("ZC0",.F.)
		ZC0->(DbDelete())
		ZC0->(MsUnLock())
	endif

	if RecLock("ZC1",.F.)
		ZC1->(DbDelete())
		ZC1->(MsUnLock())
	endif
End Transaction

U_GrvLogKa("CINTK01", "DELETE", "1", "Exclusão realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Exclusão realizada com sucesso")

/*/{Protheus.doc} GET
Realiza a consulta do contrato e local de contrato
@author Danilo José Grodzicki
@since 18/09/2019
@/version undefined

@type function
/*/
WSMETHOD GET WSSERVICE CONTRATO

Local cErro

Local oJson := Nil
Local cJson := ""

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
cErro := ValoJson(oJson,"C")
if !Empty(cErro)
	U_GrvLogKa("CINTK01", "GET", "2", cErro, cJson, oJson)
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
cJson += '		"LOCALCONTRATO": {'
cJson += '			"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOCCTR), "cp1252") + '",'
cJson += '			"razaoSocial": "' + EncodeUTF8(AllTrim(ZC1->ZC1_RAZSOC), "cp1252") + '",'
cJson += '			"nomeFantasia": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOMFAN), "cp1252") + '",'
cJson += '			"documento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DOCLOC), "cp1252") + '",'
cJson += '			"inscricaoEstadual": "' + EncodeUTF8(AllTrim(ZC1->ZC1_INSEST), "cp1252") + '",'
cJson += '			"inscricaoMunicipal": "' + EncodeUTF8(AllTrim(ZC1->ZC1_INSMUN), "cp1252") + '",'
cJson += '			"ENDERECO": {'
cJson += '				"cep": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CEPLOC), "cp1252") + '",'
cJson += '				"logradouro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_LOGLOC), "cp1252") + '",'
cJson += '				"endereco": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ENDLOC), "cp1252") + '",'
cJson += '				"numero": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NUMLOC), "cp1252") + '",'
cJson += '				"complemento": "' + EncodeUTF8(AllTrim(ZC1->ZC1_COMLOC), "cp1252") + '",'
cJson += '				"bairro": "' + EncodeUTF8(AllTrim(ZC1->ZC1_BAILOC), "cp1252") + '",'
cJson += '				"codigoMunicipioIBGE": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CMUNLO), "cp1252") + '",'
cJson += '				"cidade": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CIDLOC), "cp1252") + '",'
cJson += '				"uf": "' + EncodeUTF8(AllTrim(ZC1->ZC1_ESTLOC), "cp1252") + '"'
cJson += '			},'
cJson += '			"CONSULTOR": {'
cJson += '				"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_IDCOLO), "cp1252") + '",'
cJson += '				"nome": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOCOLO), "cp1252") + '",'
cJson += '				"idCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CACOLO), "cp1252") + '",'
cJson += '				"dsCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DECOLO), "cp1252") + '"'
cJson += '			}'
cJson += '		},'
cJson += '		"CONSULTOR": {'
cJson += '			"id": "' + EncodeUTF8(AllTrim(ZC1->ZC1_IDCOEN), "cp1252") + '",'
cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC1->ZC1_NOCOEN), "cp1252") + '",'
cJson += '			"idCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_CACOEN), "cp1252") + '",'
cJson += '			"dsCarteira": "' + EncodeUTF8(AllTrim(ZC1->ZC1_DECOEN), "cp1252") + '"'
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

/*/{Protheus.doc} RESTERRO
Seta mensagem de erro do rest
@author carlos.henrique
@since 01/03/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
User function RESTERRO(Self,cMsg,nTipo) 
DEFAULT nTipo:= 1

IF nTipo == 1
	SetRestFault(400,EncodeUtf8(cMsg))
ELSE
	SetRestFault(404,EncodeUtf8(cMsg))
ENDIF

Return .F.

/*/{Protheus.doc} RESTOK
Seta mensagem de sucesso do rest
@author carlos.henrique
@since 01/03/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
User function RESTOK(self,cMsg)

Local oRet := JsonObject():new()

oRet['message']	:= EncodeUtf8(cMsg)

self:SetResponse( oRet:toJSON() )

Return .T.

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author Danilo José Grodzicki
@since 17/09/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

// Verifica se enviou o ID do contrato
cIdEmp := oJson["EMPRESA"]:GetJsonText("idContrato")
if Empty(cIdEmp)
	Return("O código do contrato é obrigátorio.")
endif

// Verifica se enviou o ID do local do contrato
cIdLoc := oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("id")
if Empty(cIdLoc)
	Return("O código do local do contrato é obrigatório.")
endif

if cTipo == "E" .or. cTipo == "C"  // Exclusão ou Consulta
	
	// Verifica se o contrato está cadastrado
	if !ZC0->(DbSeek(xFilial("ZC0")+Padr(AllTrim(cIdEmp),TamSX3("ZC0_CODIGO")[1]," ")))
		Return( "O contrato " + AllTrim(cIdEmp) + " não existe." )
	endif
	
	// Verifica se o contrato e o local do contrato está cadastrado
	if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdEmp),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cIdLoc),TamSX3("ZC1_LOCCTR")[1]," ")))
		Return("O contrato " + AllTrim(cIdEmp) + " e o local do contrato " + AllTrim(cIdLoc) + " não existe.")
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

// Verifica se enviou o estado do endereço do local do contrato
cUfCont := oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("uf")
if Empty(cUfCont)
	Return("O estado do endereço do local do contrato é obrigatório.")
endif

// Verifica se enviou o código do município do endereço do local do contrato
cCodMunCon := oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("codigoMunicipioIBGE")
if Empty(cCodMunCon)
	Return("O código do município do endereço do local do contrato é obrigatório.")
endif

// Verifica se o estado e código do município do endereço do local do contrato são válidos
if !CC2->(DbSeek(xFilial("CC2")+cUfCont+cCodMunCon))
	Return("O estado " + AllTrim(cUfCont) + "e/ou código do municipio " + AllTrim(cCodMunCon) + " do endereço do local do contrato inválido.")
endif
cCidCon := AllTrim(CC2->CC2_MUN)

// Valida a inscrição estadual
cInsEst := oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("inscricaoEstadual")
if !Empty(cInsEst)
	if AllTrim(cUfCont) == "DF"  // Distrito Federal deve-se acrescentar um 0 (zero) à esquerda.
		cInsEst := "0" + AllTrim(cInsEst)
	else
		cInsEst := AllTrim(cInsEst)
	endif
    if !IE(cInsEst, AllTrim(cUfCont), .F.)
	    Return("Inscrição Estadual " + AllTrim(cInsEst) + " inválida.")
    endif
endif

Return("")

/*/{Protheus.doc} GravaCon
Realiza a gravação do contrato e local de contrato
@author TOTVS
@since 18/09/2019
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
cRazSoc := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("razaoSocial"))
cNomFan := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("nomeFantasia"))
cDocLoc := oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("documento")
cInsEst := oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("inscricaoEstadual")
cInsNum := oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("inscricaoMunicipal")
cCepLoc := oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("cep")
cLogLoc := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("logradouro"))
cEndLoc := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("endereco"))
cNumLoc := oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("numero")
cComLoc := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("complemento"))
cBaiLoc := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]["ENDERECO"]:GetJsonText("bairro"))
cIdCoLo := oJson["EMPRESA"]["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("id")
cNoCoLo := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("nome"))
cCaCoLo := oJson["EMPRESA"]["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("idCarteira")
cDeCoLo := DecodeUTF8(oJson["EMPRESA"]["LOCALCONTRATO"]["CONSULTOR"]:GetJsonText("dsCarteira"))
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
		ZC0->ZC0_NREDUZ := cNReduz
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
	ZC0->(MsUnLock())
	
	if ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdEmp),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cIdLoc),TamSX3("ZC1_LOCCTR")[1]," ")))
		RecLock("ZC1",.F.)
	else
		RecLock("ZC1",.T.)
	endif
		ZC1->ZC1_FILIAL := xFilial("ZC1")
		ZC1->ZC1_CODIGO := cIdEmp
		ZC1->ZC1_LOCCTR := cIdLoc
		ZC1->ZC1_RAZSOC := cRazSoc
		ZC1->ZC1_NOMFAN := cNomFan
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
		ZC1->ZC1_IDCOEN := cIdCoEn
		ZC1->ZC1_NOCOEN := cNoCoEn
		ZC1->ZC1_CACOEN := cCaCoEn
		ZC1->ZC1_DECOEN := cDeCoEn
		ZC1->ZC1_DTINTE := Date()
		ZC1->ZC1_HRINTE := Time()
		ZC1->ZC1_JSON   := cJson
	ZC1->(MsUnLock())

End Transaction

Return Nil

/*/{Protheus.doc} GrvLogKa
Realiza a gravação do log da integração Kairós
@author danilo.grodzicki
@since 29/04/2020
@version 12.1.25
@param:
		cIntegra:
			CINTK01
		cMetodo: método
			GET
			POST
			PUT
			DELETE
			POSTDW3
			PUTDW3
			DELETEDW3
		cStatus: status da integração
			"1" = Sucesso
			"2" = Erro
		cMensagem: mensagem da integração
		cJson: payload
		oJson: objeto Json
@type user function
/*/
User Function GrvLogKa(cIntegra, cMetodo, cStatus, cMensagem, cJson, oJson)

Local nI
Local cChave
Local cDescInteg

if cIntegra == "CINTK01"
	// Pega o ID do contrato e o ID do local do contrato
	cChave     := xFilial("ZC1") + Padr(AllTrim(oJson["EMPRESA"]:GetJsonText("idContrato")),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(oJson["EMPRESA"]["LOCALCONTRATO"]:GetJsonText("id")),TamSX3("ZC1_LOCCTR")[1]," ")
	cDescInteg := "CONTRATO/LOCAL CONTRATO"
elseif cIntegra == "CINTK02"
	// Pega o ID da configuração de cobrança, o ID do local do contrato e o ID da configuração do faturamento
	cChave     := xFilial("ZC3") + Padr(AllTrim(oJson["CONFIGURACAO"]:GetJsonText("id")),TamSX3("ZC3_IDCOBR")[1]," ") + Padr(AllTrim(oJson["CONFIGURACAO"]:GetJsonText("idContrato")),TamSX3("ZC3_IDCONT")[1]," ") + Padr(AllTrim(oJson["CONFIGURACAO"]:GetJsonText("idConfiguracaofaturamento")),TamSX3("ZC3_IDPGTO ")[1]," ")
	cDescInteg := "CONFIGURACAO COBRANCA"
elseif cIntegra == "CINTK03"
	// Pega o ID da configuração do faturamento e o ID do contrato
	cChave     := xFilial("ZC4") + Padr(AllTrim(oJson["CONFIGURACAO"]:GetJsonText("id")),TamSX3("ZC4_IDFATU")[1]," ") + Padr(AllTrim(oJson["CONFIGURACAO"]:GetJsonText("idContrato")),TamSX3("ZC4_IDCONT")[1]," ")
	cDescInteg := "CONFIGURACAO FATURAMENTO"
elseif cIntegra == "CINTK04"
	// Pega o lote do faturamento e a sequencia do lote do faturamento
	cChave     := Padr(AllTrim(oJson["sintetico"]:GetJsonText("lote")),TamSX3("ZC6_LOTE")[1]," ") + Padr(AllTrim(oJson["sintetico"]:GetJsonText("seqlote")),TamSX3("ZC6_SEQLOT")[1]," ")
	cDescInteg := "FATURAMENTO"
elseif cIntegra == "CINTK05"
	// Pega o ID da folha
	cChave     := Padr(AllTrim(oJson["sintetico"]:GetJsonText("idfolha")),TamSX3("ZC7_IDFOL")[1]," ") 
	cDescInteg := "BOLSA AUXILIO"
elseif cIntegra == "CINTK06" .or. cIntegra == "CINTK06M"
	// Pega o ID do estagiário/aprendiz
	cChave     := xFilial("SRA") + Padr(oJson["sintetico"]["analitico"]:GetJsonText("id"),TamSX3("RA_XID")[1]," ")
	cDescInteg := "TCETCA"
elseif cIntegra == "CINTK07"
	// Pega o ID da configuração de folha
	cChave     := xFilial("ZC2") + Padr(AllTrim(oJson["configuracao"]:GetJsonText("id")),TamSX3("ZC2_IDFOLH")[1]," ")
	cDescInteg := "CONFIGURACAO FOLHA"
elseif cIntegra == "CINTK08"
	if (cMetodo == "GRVCRD" .or. cMetodo == "INCVCI") .and. cStatus == "1"
		cChave := xFilial("ZCF") + cIdMovime
	elseif (cMetodo == "DELCRD" .or. cMetodo == "EXCVCI") .and. cStatus == "1"
		cChave := xFilial("ZCF") + cIdMovime
	endif
	cDescInteg := "CREDITOS NAO IDENTIFICADOS"
elseif cIntegra == "CINTK09"
	cChave     := ""
	cDescInteg := "CONSULTA BANCO (SA6)"
elseif cIntegra == "CINTK10"
	// Pega o ID de negociação
	if !Empty(cJson)
		cChave := xFilial("ZC9") + PadR(AllTrim(oJson[iif(cTipInt == "5","agrupamento","sintetico")]:GetJsonText("idnegociacao")),TamSX3("ZC9_IDNEG")[1]," ")
	endif
	if cTipInt == "1"
		cDescInteg := "NEGOCIACAO - PRORROGACAO"
	elseif cTipInt == "2"
		cDescInteg := "NEGOCIACAO - ABATIMENTO"
	elseif cTipInt == "3"
		cDescInteg := "NEGOCIACAO - PARCELAMENTO"
	elseif cTipInt == "4"
		cDescInteg := "NEGOCIACAO - CANCELAMENTO"
	elseif cTipInt == "5"
		cDescInteg := "NEGOCIACAO - AGRUPAMENTO"
	elseif cTipInt == "6"
		cDescInteg := "NEGOCIACAO - SERASA"
	elseif cTipInt == "7"
		cDescInteg := "NEGOCIACAO - GLOBAL"
	else
		cDescInteg := "NEGOCIACAO - TIPO INVALIDO"
	endif
elseif cIntegra == "CINTK11"
	// Pega o ID do agendamento
	if cTipAge == "1"
		cDescInteg := "AGENDAMENTO - BOLSAAUXILIO"
	else
		cDescInteg := "AGENDAMENTO - TIPO INVALIDO"
	endif
elseif cIntegra == "CINTK16"
	// Pega o ID do contrato e o ID do local do contrato
	cChave     := xFilial("ZC1") + Padr(AllTrim(oJson["LOCALCONTRATO"]:GetJsonText("idContrato")),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(oJson["LOCALCONTRATO"]:GetJsonText("id")),TamSX3("ZC1_LOCCTR")[1]," ")
	cDescInteg := "INTEGRA LOCAL CONTRATO"
elseif cIntegra == "CINTK17"
	// Pega o ID do contrato
	cChave     := xFilial("ZC0") + Padr(AllTrim(oJson["EMPRESA"]:GetJsonText("idContrato")),TamSX3("ZC0_CODIGO")[1]," ")
	cDescInteg := "INTEGRA CONTRATO"
endif

if cIntegra == "CINTK11"
	for nI = 1 to Len(aAgenda)
		ZCL->(RecLock("ZCL", .T.))
			ZCL->ZCL_FILIAL := xFilial("ZCL")
			ZCL->ZCL_CHAVE  := aAgenda[nI][01] + "REVISAO: " + aAgenda[nI][02]
			ZCL->ZCL_DESCRI := cDescInteg
			ZCL->ZCL_METODO := cMetodo
			ZCL->ZCL_STATUS := cStatus
			ZCL->ZCL_MSG    := cMensagem
			ZCL->ZCL_DTINI  := dDtIniInt
			ZCL->ZCL_HRINI  := cHrIniInt
			ZCL->ZCL_ENVDW3 := cHrIniDw3
			ZCL->ZCL_RETDW3 := cHrFimDw3
			ZCL->ZCL_DTINTE := aAgenda[nI][03]
			ZCL->ZCL_HRINTE := aAgenda[nI][04]
			ZCL->ZCL_JSON   := cJson
		ZCL->(MsUnLock())
	next
else
	ZCL->(RecLock("ZCL", .T.))
		ZCL->ZCL_FILIAL := xFilial("ZCL")
		ZCL->ZCL_CHAVE  := cChave
		ZCL->ZCL_DESCRI := cDescInteg
		ZCL->ZCL_METODO := cMetodo
		ZCL->ZCL_STATUS := cStatus
		if cIntegra == "CINTK06M"
			ZCL->ZCL_MSG    :="Veja o campo ZCL_EXEAUT"
			ZCL->ZCL_EXEAUT := cMensagem
		else
			ZCL->ZCL_MSG    := cMensagem
		endif
		ZCL->ZCL_DTINI  := dDtIniInt
		ZCL->ZCL_HRINI  := cHrIniInt
		ZCL->ZCL_ENVDW3 := cHrIniDw3
		ZCL->ZCL_RETDW3 := cHrFimDw3
		ZCL->ZCL_DTINTE := Date()
		ZCL->ZCL_HRINTE := Time()
		ZCL->ZCL_JSON   := cJson
	ZCL->(MsUnLock())
endif

Return