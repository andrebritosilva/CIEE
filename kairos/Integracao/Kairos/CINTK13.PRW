#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} CINTK13
Rotina de integração das unidades Kairos 
@author carlos.henrique
@since 19/03/2019
@version undefined
@type function
/*/
USER FUNCTION CINTK13(nRecno) 
Local nCnta:= 0
Local oJson:= nil
Local cMApo:= ""
Local cCodUni:= ""
Local lLock:= .F.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK13] Inicio Unidades RECNO:" + CVALTOCHAR(nRecno))

DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

IF !EMPTY(ZCQ->ZCQ_JSON)
	oJson:= JsonObject():new()
	oJson:fromJson(ZCQ->ZCQ_JSON)   
	
	cMApo:= ""
	FOR nCnta:=1 to LEN(oJson["emailApoio"])
		cMApo+= oJson["emailApoio"][nCnta]+ ";"
	NEXT

	cCodUni:= AVKEY(oJson:GetJsonText("codigo"),"ZCN_CODIGO")
	
	DbSelectarea("ZCN")
	ZCN->(DBSETORDER(1))
	lLock:= !DBSEEK(XFILIAL("ZCN")+cCodUni)

	RECLOCK("ZCN",lLock)
		ZCN_FILIAL:= XFILIAL("ZCN")
		ZCN_CODIGO:= oJson:GetJsonText("codigo")
		ZCN_CEP   := oJson["endereco"]:GetJsonText("cep")
		ZCN_BAIRRO:= oJson["endereco"]:GetJsonText("bairro")
		ZCN_CIDADE:= oJson["endereco"]:GetJsonText("cidade")
		ZCN_NUMERO:= oJson["endereco"]:GetJsonText("numero")
		ZCN_UF    := oJson["endereco"]:GetJsonText("estado")
		ZCN_COMPL := oJson["endereco"]:GetJsonText("complemento")
		ZCN_END   := oJson["endereco"]:GetJsonText("logradouro")
		ZCN_TPEND := oJson["endereco"]:GetJsonText("tipoLogradouro")
		ZCN_DLOCAL:= oJson:GetJsonText("descricaoLocal")
		ZCN_CODGER:= oJson:GetJsonText("codigoGerencia")
		ZCN_MAILRE:= oJson["responsavel"]:GetJsonText("email")
		ZCN_NOMRE := oJson["responsavel"]:GetJsonText("nome")
		ZCN_NRERED:= oJson["responsavel"]:GetJsonText("nomeReduzido")
		ZCN_SITUAC:= iif(oJson["situacao"],"1","2")
		ZCN_CNPJ  := oJson:GetJsonText("cnpj")
		ZCN_DELOAB:= oJson:GetJsonText("descricaoLocalAbreviada")
		ZCN_FONE  := oJson:GetJsonText("telefone")
		ZCN_FOCOBR:= oJson:GetJsonText("telefoneCobranca")
		ZCN_MAILAP:= cMApo
		ZCN_CRESTA:= oJson:GetJsonText("crEstagio")
		ZCN_CRPRES:= oJson:GetJsonText("crProcessoEspecial")
		ZCN_CRAPRC:= oJson:GetJsonText("crAprendizCapacitador")
		ZCN_CRAPRE:= oJson:GetJsonText("crAprendizEmpregador")
		ZCN_CRSEGU:= oJson:GetJsonText("crSeguro")
		ZCN_MOEND := oJson:GetJsonText("mostrarEndereco")
	MSUNLOCK()

	RECLOCK("ZCQ",.F.)
		ZCQ->ZCQ_STATUS:= "2" 								 //STATUS
		ZCQ->ZCQ_MSG   := "Integração realizada com sucesso" //MENSAGEM
	MSUNLOCK()	

	FreeObj(oJson)	 
ENDIF

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK13] Fim Unidades RECNO:" + CVALTOCHAR(nRecno))

RETURN