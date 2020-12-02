#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK03
Serviço de integração do Faturamento de CI/CIA/RASTREAMENTO
@author carlos.henrique
@since 19/03/2019
@version undefined
@type function
/*/
USER FUNCTION CINTK04(nRecno) 

Local cErro

Local cMsgOK := ""

Private oRet       := Nil
Private oJson      := Nil
Private cJson      := Nil
Private nQtde      := 0
Private cLote      := space(016)
Private nValor     := 0
Private cSeqLot    := space(015)
Private cProFat    := space(001)
Private cLotRas    := space(016)
Private cIdFatu    := space(019)
Private cIdCont    := space(015)
Private cIdLCont   := space(015)
Private cConFat    := space(015)
Private cIdFolha   := space(015)
Private cConCob    := space(015)
Private cTipPro    := space(001)
Private cCpfEst    := space(011)
Private cTipFat    := space(001)
Private nVlrTot    := 0
Private cDatVen    := space(008)
Private cBcoFat    := space(003)
Private cMsgNot    := space(150)
Private cIdEstu    := space(015)
Private cNomEst    := space(150)
Private cNomSoc    := space(150)
Private cCompet    := space(006)
Private cTceTca    := space(015)
Private cIdCotr    := space(015)
Private cLocCon    := space(015)
Private cIdKairos  := space(019)
Private cTipFrm    := ""
Private nVlrEmp    := 0
Private nAutPpg    := 0
Private nAutVpg    := 0
Private cAutUpg    := ""
Private nAutPrc    := 0
Private nAutVrc    := 0
Private cAutUrc    := ""
Private cAutFge    := ""
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""
Private lErroTenta := .F.
Private cNumPed    := space(15)

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK04] INICIO - Serviço de integração do Faturamento de CI/CIA/RASTREAMENTO - RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("SA6")
SA6->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

DbSelectArea("ZC5")
ZC5->(DbSetOrder(08))

DbSelectArea("ZC6")
ZC6->(DbSetOrder(01))

DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

IF !EMPTY(ZCQ->ZCQ_JSON)

	oJson:= JsonObject():new()
	oJson:fromJson(ZCQ->ZCQ_JSON)   
	
	cJson := ZCQ->ZCQ_JSON

	// if  At("sintetico",cJson) == 0
	// 	RECLOCK("ZCQ",.F.)
	// 		ZCQ->ZCQ_STATUS := "1" 	
	// 		ZCQ->ZCQ_CODE   := "404"  // Erro
	// 		ZCQ->ZCQ_MSG    := "Payload inválido"
	// 	MSUNLOCK()	
	// 	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK03] FIM - Serviço de integração do Faturamento de CI/CIA/RASTREAMENTO - RECNO:" + CVALTOCHAR(nRecno))
	// 	Return
	// endif

	//Avalia o campo operação ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"I")
			if Empty(cErro)
				GravaZc6(oJson)
				cMsgOK := "Integração do Faturamento de CI/CIA/RASTREAMENTO cadastrada com sucesso !!!"
			endif

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"A")
			if Empty(cErro)
				// Realiza a alteração do contrato e local de contrato
				GravaZc6(oJson)
				cMsgOK := "Integração do Faturamento de CI/CIA/RASTREAMENTO alteradas com sucesso !!!"
			endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"E")

			if Empty(cErro)

				// Exclui o registro da tabela ZC6
				Begin Transaction
					if RecLock("ZC6",.F.)
						ZC6->(DbDelete())
						ZC6->(MsUnLock())
					endif
				End Transaction

				cMsgOK := "Integração do Faturamento de CI/CIA/RASTREAMENTO excluída com sucesso !!!"

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

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK04] FIM - Serviço de integração do Faturamento de CI/CIA/RASTREAMENTO - RECNO:" + CVALTOCHAR(nRecno))

return

/*/{Protheus.doc} FATURA
Serviço de integração do Faturamento de CI/CIA/RASTREAMENTO
@author carlos.henrique
@since 01/03/2019
@version undefined
@type class
/*/
WSRESTFUL FATURA DESCRIPTION "Serviço de integração do Faturamento de CI - CIA - Rastreamento" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza a inclusão de faturamento de nota";
	WSSYNTAX "/FATURA"
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a alteração para cancelamento de nota";
	WSSYNTAX "/FATURA"
	WSMETHOD DELETE; 
	DESCRIPTION "Realiza a alteração para cancelamento de nota";
	WSSYNTAX "/FATURA"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a alteração para cancelamento de nota";
	WSSYNTAX "/FATURA"
END WSRESTFUL
 
/*/{Protheus.doc} POST
Realiza a inclusão de faturamento de nota
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD POST WSSERVICE FATURA

Local cErro

Private oRet      := Nil
Private oJson     := Nil
Private cJson     := Nil
Private nQtde     := 0
Private cLote     := space(016)
Private nValor    := 0
Private cSeqLot   := space(015)
Private cProFat   := space(001)
Private cLotRas   := space(016)
Private cIdFatu   := space(019)
Private cIdCont   := space(015)
Private cIdLCont  := space(015)
Private cConFat   := space(015)
Private cIdFolha  := space(015)
Private cConCob   := space(015)
Private cTipPro   := space(001)
Private cCpfEst   := space(011)
Private cTipFat   := space(001)
Private nVlrTot   := 0
Private cDatVen   := space(008)
Private cBcoFat   := space(003)
Private cMsgNot   := space(150)
Private cIdEstu   := space(015)
Private cNomEst   := space(150)
Private cNomSoc   := space(150)
Private cCompet   := space(006)
Private cTceTca   := space(015)
Private cIdCotr   := space(015)
Private cLocCon   := space(015)
Private cIdKairos := space(019)
Private cTipFrm   := ""
Private nVlrEmp   := 0
Private nAutPpg   := 0
Private nAutVpg   := 0
Private cAutUpg   := ""
Private nAutPrc   := 0
Private nAutVrc   := 0
Private cAutUrc   := ""
Private cAutFge   := ""
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cNumPed   := space(15)

DbSelectArea("SA6")
SA6->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

DbSelectArea("ZC6")
ZC6->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"I")
if !Empty(cErro)
	U_GrvLogKa("CINTK04", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

// Realiza a gravação na tabela ZC6
GravaZc6(oJson)

U_GrvLogKa("CINTK04", "POST", "1", "Integracao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integracao realizada com sucesso")

/*/{Protheus.doc} PUT
Realiza a atualizacao de Faturamento de nota
@author carlos.henrique
@since 01/03/2019
@version undefined

@type function
/*/
WSMETHOD PUT WSSERVICE FATURA

Local cErro

Private oRet      := Nil
Private oJson     := Nil
Private cJson     := Nil
Private nQtde     := 0
Private cLote     := space(016)
Private nValor    := 0
Private cSeqLot   := space(015)
Private cProFat   := space(001)
Private cLotRas   := space(016)
Private cIdFatu   := space(019)
Private cIdCont   := space(015)
Private cIdLCont  := space(015)
Private cConFat   := space(015)
Private cIdFolha  := space(015)
Private cConCob   := space(015)
Private cTipPro   := space(001)
Private cCpfEst   := space(011)
Private cTipFat   := space(001)
Private nVlrTot   := 0
Private cDatVen   := space(008)
Private cBcoFat   := space(003)
Private cMsgNot   := space(150)
Private cIdEstu   := space(015)
Private cNomEst   := space(150)
Private cNomSoc   := space(150)
Private cCompet   := space(006)
Private cTceTca   := space(015)
Private cIdCotr   := space(015)
Private cLocCon   := space(015)
Private cIdKairos := space(019)
Private cTipFrm   := ""
Private nVlrEmp   := 0
Private nAutPpg   := 0
Private nAutVpg   := 0
Private cAutUpg   := ""
Private nAutPrc   := 0
Private nAutVrc   := 0
Private cAutUrc   := ""
Private cAutFge   := ""
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cNumPed   := space(15)

DbSelectArea("SA6")
SA6->(DbSetOrder(01))

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

DbSelectArea("ZC6")
ZC6->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"A")
if !Empty(cErro)
	U_GrvLogKa("CINTK04", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

// Realiza a gravação na tabela ZC6
GravaZc6(oJson)

U_GrvLogKa("CINTK04", "PUT", "1", "Atualização realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Atualização realizada com sucesso")

/*/{Protheus.doc} DELETE
Realiza a exclusão de Faturamento de nota
@author Danilo José Grodzicki
@since 01/10/2019
@version undefined

@type function
/*/
WSMETHOD DELETE WSSERVICE FATURA

Local cErro

Private oRet      := Nil
Private oJson     := Nil
Private cJson     := Nil
Private nQtde     := 0
Private cLote     := space(016)
Private nValor    := 0
Private cSeqLot   := space(015)
Private cProFat   := space(001)
Private cLotRas   := space(016)
Private cIdFatu   := space(019)
Private cIdCont   := space(015)
Private cIdLCont  := space(015)
Private cConFat   := space(015)
Private cIdFolha  := space(015)
Private cConCob   := space(015)
Private cTipPro   := space(001)
Private cCpfEst   := space(011)
Private cTipFat   := space(001)
Private nVlrTot   := 0
Private cDatVen   := space(008)
Private cBcoFat   := space(003)
Private cMsgNot   := space(150)
Private cIdEstu   := space(015)
Private cNomEst   := space(150)
Private cNomSoc   := space(150)
Private cCompet   := space(006)
Private cTceTca   := space(015)
Private cIdCotr   := space(015)
Private cLocCon   := space(015)
Private cIdKairos := space(019)
Private cTipFrm   := ""
Private nVlrEmp   := 0
Private nAutPpg   := 0
Private nAutVpg   := 0
Private cAutUpg   := ""
Private nAutPrc   := 0
Private nAutVrc   := 0
Private cAutUrc   := ""
Private cAutFge   := ""
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cNumPed   := space(15)

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

DbSelectArea("ZC6")
ZC6->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"E")
if !Empty(cErro)
	U_GrvLogKa("CINTK04", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

// Exclui o registro da tabela ZC6
Begin Transaction
	if RecLock("ZC6",.F.)
		ZC6->(DbDelete())
		ZC6->(MsUnLock())
	endif
End Transaction

U_GrvLogKa("CINTK04", "DELETE", "1", "Exclusao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Exclusao realizada com sucesso")

/*/{Protheus.doc} GET
Realiza a consulta de Faturamento de nota
@author Danilo José Grodzicki
@since 01/10/2019
@/version undefined

@type function
/*/

WSMETHOD GET WSSERVICE FATURA

Local cErro

Local cJson := Nil

Private oRet      := Nil
Private oJson     := Nil
Private nQtde     := 0
Private cLote     := space(016)
Private nValor    := 0
Private cSeqLot   := space(015)
Private cProFat   := space(001)
Private cLotRas   := space(016)
Private cIdFatu   := space(019)
Private cIdCont   := space(015)
Private cIdLCont  := space(015)
Private cConFat   := space(015)
Private cIdFolha  := space(015)
Private cConCob   := space(015)
Private cTipPro   := space(001)
Private cCpfEst   := space(011)
Private cTipFat   := space(001)
Private nVlrTot   := 0
Private cDatVen   := space(008)
Private cBcoFat   := space(003)
Private cMsgNot   := space(150)
Private cIdEstu   := space(015)
Private cNomEst   := space(150)
Private cNomSoc   := space(150)
Private cCompet   := space(006)
Private cTceTca   := space(015)
Private cIdCotr   := space(015)
Private cLocCon   := space(015)
Private cIdKairos := space(019)
Private cTipFrm   := ""
Private nVlrEmp   := 0
Private nAutPpg   := 0
Private nAutVpg   := 0
Private cAutUpg   := ""
Private nAutPrc   := 0
Private nAutVrc   := 0
Private cAutUrc   := ""
Private cAutFge   := ""
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""
Private cNumPed   := space(15)

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))

DbSelectArea("ZC3")
ZC3->(DbSetOrder(01))

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))

DbSelectArea("ZC6")
ZC6->(DbSetOrder(01))

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"C")
if !Empty(cErro)
	U_GrvLogKa("CINTK04", "GET", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

cJson := '{'
cJson += '	"sintetico": {'
cJson += '		"idfatura": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDFATU), "cp1252") + '",'
cJson += '		"lote": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOTE), "cp1252") + '",'
cJson += '		"seqlote": "' + EncodeUTF8(AllTrim(ZC6->ZC6_SEQLOT), "cp1252") + '",'
cJson += '		"processo": "' + EncodeUTF8(AllTrim(ZC6->ZC6_PROFAT), "cp1252") + '",'
cJson += '		"loterastreamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOTRAS), "cp1252") + '",'
cJson += '		"idcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDCONT), "cp1252") + '",'
cJson += '		"idlocalcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOCCON), "cp1252") + '",'
cJson += '		"idlocalremessa": "' + EncodeUTF8(AllTrim(ZC6->ZC6_LOCREM), "cp1252") + '",'
cJson += '		"idconfiguracaofaturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CONFAT), "cp1252") + '",'
cJson += '		"idfolha": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDFOLH), "cp1252") + '",'
cJson += '		"idconfiguracaocobranca": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CONCOB), "cp1252") + '",'
cJson += '		"quantidade_tce_tca": "' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_QTDE,14,2)), "cp1252") + '",'
cJson += '		"tipoproduto": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPPRO), "cp1252") + '",'
cJson += '		"valortotal": "' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_VLRTOT,14,2)), "cp1252") + '",'
cJson += '		"datavencimento": "' + EncodeUTF8(AllTrim(DTOC(ZC6->ZC6_DATVEN)), "cp1252") + '",'
cJson += '		"bancofaturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_BCOFAT), "cp1252") + '",'
cJson += '		"mensagemnota": "' + EncodeUTF8(AllTrim(ZC6->ZC6_MSGNOT), "cp1252") + '",'
cJson += '		"analitico": [{'
cJson += '			"id": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDESTU), "cp1252") + '",'
cJson += '			"cpf": "' + EncodeUTF8(AllTrim(ZC6->ZC6_CPFEST), "cp1252") + '",'
cJson += '			"nome": "' + EncodeUTF8(AllTrim(ZC6->ZC6_NOMEST), "cp1252") + '",'
cJson += '			"nomesocial": "' + EncodeUTF8(AllTrim(ZC6->ZC6_NOMSOC), "cp1252") + '",'
cJson += '			"competencia": "' + EncodeUTF8(AllTrim(ZC6->ZC6_COMPET), "cp1252") + '",'
cJson += '			"codigo_tce_tca": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TCETCA), "cp1252") + '",'
cJson += '			"idcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDCOTR), "cp1252") + '",'
cJson += '			"idlocalcontrato": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDLCOT), "cp1252") + '",'
cJson += '			"tipo_faturamento": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPFAT), "cp1252") + '",'
cJson += '			"valor": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_VALOR,14,2)), "cp1252") + ','
cJson += '			"previa": "' + EncodeUTF8(AllTrim(ZC6->ZC6_PREVIA), "cp1252") + '",'
cJson += '			"idfaturakairos": "' + EncodeUTF8(AllTrim(ZC6->ZC6_IDKAIR), "cp1252") + '",'
cJson += '			"estorno_previa": {'
cJson += '				"idfatura": "' + EncodeUTF8(LEFT(ZC6->ZC6_ESTPRE,15), "cp1252") + '",'
cJson += '				"id": "' + EncodeUTF8(RIGHT(ZC6->ZC6_ESTPRE,15), "cp1252") + '"'
cJson += '			},'
cJson += '			"repasse": {'
cJson += '				"frm": {'
cJson += '					"tipo": "' + EncodeUTF8(AllTrim(ZC6->ZC6_TIPFRM), "cp1252") + '"'
cJson += '				},'
cJson += '				"empresa": {'
cJson += '					"valor": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_VLREMP,14,2)), "cp1252")
cJson += '				},'
cJson += '				"autonomos": {'
cJson += '					"percentual_pagar": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_AUTPPG,14,2)), "cp1252") + ','
cJson += '					"valor_pagar": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_AUTVPG,14,2)), "cp1252") + ','
cJson += '					"unidade_pagar": "' + EncodeUTF8(AllTrim(ZC6->ZC6_AUTUPG), "cp1252") + '",'
cJson += '					"percentual_receber": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_AUTPRC,14,2)), "cp1252") + ','
cJson += '					"valor_receber": ' + EncodeUTF8(AllTrim(Str(ZC6->ZC6_AUTVRC,14,2)), "cp1252") + ','
cJson += '					"unidade_receber": "' + EncodeUTF8(AllTrim(ZC6->ZC6_AUTURC), "cp1252") + '",'
cJson += '					"fato_gerador": "' + EncodeUTF8(AllTrim(ZC6->ZC6_AUTFGE), "cp1252") + '"'
cJson += '				}'
cJson += '			}'
cJson += '		}]'
cJson += '	}'
cJson += '}'

::SetResponse(cJson)

Return .T.

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author Danilo José Grodzicki
@since 01/10/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

Local nI

// Verifica se enviou o lote do faturamento
cLote := oJson["sintetico"]:GetJsonText("lote")
if Empty(cLote)
	Return("O lote do faturamento é obrigatorio.")
endif

// Verifica se enviou a sequencia do lote do faturamento
cSeqLot := oJson["sintetico"]:GetJsonText("seqlote")
if Empty(cSeqLot)
	Return("A sequencia do lote é obrigatorio.")
endif

// Em conversa com o Marcelo Henrique o banco deve ser pego da configuração de faturamento ou cobrança.
// Verifica se enviou o banco do faturamento
//cBcoFat := oJson["sintetico"]:GetJsonText("bancofaturamento")
//if Empty(cBcoFat)
//	Return("O banco de faturamento é obrigatorio.")
//else
//	if !SA6->(DbSeek(xFilial("SA6")+cBcoFat))
//		Return("Banco de faturamento inválido: " + AllTrim(cBcoFat))
//	endif
//endif

if cTipo == "E" .or. cTipo == "C"  // Exclusão ou Consulta

	// Verifica se a integração de faturamento já está cadastrado
	if !ZC6->(DbSeek(Padr(AllTrim(cLote),TamSX3("ZC6_LOTE")[1]," ") + Padr(AllTrim(cSeqLot),TamSX3("ZC6_SEQLOT")[1]," ")  ))
		Return("O lote " + AllTrim(cLote) + " e sequencia do lote " + AllTrim(cSeqLot) + "  não existe.")
	endif	
	
endif

// Valida processo de faturamento
cProFat := oJson["sintetico"]:GetJsonText("processo")
if Empty(cProFat) .or. !(cProFat $ "1234567")
	Return("Processo de faturamento " + AllTrim(cProFat) + " inválido.")
endif	

// Verifica se enviou o ID do faturamento
//cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
cIdFatu := PegaIdFatu()
if Empty(cIdFatu)
	Return("O ID do faturamento é obrigatório.")
endif

// Verifica se enviou o ID do contrato
cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
if Empty(cIdCont)
	Return("O ID do contrato é obrigatório.")
endif

// Verifica se enviou o ID do local do contrato
cIdLCont := oJson["sintetico"]:GetJsonText("idlocalcontrato")
if Empty(cIdLCont)
	Return("O ID do local do contrato é obrigatório.")
endif

// Verifica se o contrato e o local do contrato existe
if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdCont),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cIdLCont),TamSX3("ZC1_LOCCTR")[1]," ") ))
	lErroTenta := .T.
	Return("O ID do contrato " + AllTrim(cIdCont) + " e o local do contrato " + AllTrim(cIdLCont) + " não existe.")
endif

cLocRem := oJson["sintetico"]:GetJsonText("idlocalremessa")
if !Empty(cLocRem)
	// Verifica se o contrato e local de remessa existe na tabela ZC1
	if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdCont),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cLocRem),TamSX3("ZC1_LOCCTR")[1]," ")))
		lErroTenta := .T.
		Return("O contrato " + AllTrim(cIdCont) + " e local de remessa " + AllTrim(cLocRem) + " não existe.")
	endif	
endif

// Verifica se enviou o ID da configuração do faturamento
cConFat := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
if Empty(cConFat)
	Return("O ID da configuração do faturamento é obrigatório.")
endif

// Valida idfolha
cIdFolha := oJson["sintetico"]:GetJsonText("idfolha")
if !Empty(cIdFolha)
	cIdFolha:= Padr(AllTrim(cIdFolha),TamSX3("ZC7_IDFOL")[1]," ")
	dbSelectArea("ZC7")
	ZC7->(dbSetOrder(1))
	IF !ZC7->(dbSeek(cIdFolha))
		lErroTenta := .T.
		Return("O ID da folha " + AllTrim(cIdFolha) + " não existe.")
	endif	
endif

// Verifica se a configuração de faturamento existe na tabela ZC4 - Configurações de faturamento
if !ZC4->(DbSeek(xFilial("ZC4") + Padr(AllTrim(cConFat),TamSX3("ZC4_IDFATU")[1]," ") + Padr(AllTrim(cIdCont),TamSX3("ZC4_IDCONT")[1]," ")))
	lErroTenta := .T.
	Return("O ID da configuração de faturamento " + AllTrim(cConFat) + " para o ID do contrato " + AllTrim(cIdCont) + " não existe.")
endif

// Verifica se enviou o ID da configuração de cobrança
cConCob := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
if Empty(cConCob)
	Return("O ID da configuração de cobrança é obrigatório.")
endif

// Verifica se a configuração de cobrança existe na tabela ZC3 - Configurações de cobrança
if !ZC3->(DbSeek(xFilial("ZC3") + Padr(AllTrim(cConCob),TamSX3("ZC3_IDCOBR")[1]," ") + Padr(AllTrim(cIdCont),TamSX3("ZC3_IDCONT")[1]," ") + Padr(AllTrim(cConFat),TamSX3("ZC3_IDPGTO")[1]," ") ))
	lErroTenta := .T.
	Return("O ID da configuração de cobrança " + AllTrim(cConCob) + " para o código do contrato " + AllTrim(cIdCont) + " e o ID da configuração de faturamento " + AllTrim(cConFat) + " não existe.")
endif

// Verifica se enviou o tipo produto válido
cTipPro := oJson["sintetico"]:GetJsonText("tipoproduto")
if Empty(cTipPro) .or. !(cTipPro $ "12")
	Return("Tipo produto " + AllTrim(cTipPro) + " inválido.")
endif

cDatVen := oJson["sintetico"]:GetJsonText("datavencimento")
if Empty(CTOD(cDatVen)) 
	Return("Data de vencimento " + AllTrim(cDatVen) + " inválida.")
endif

for nI = 1 to Len(oJson["sintetico"]["analitico"])

	// Verifica se o tipo de repasse FRM é válido
	cIdEst := oJson["sintetico"]["analitico"][nI]:GetJsonText("id")
	if Empty(cIdEst)
		Return("Id estudante " + AllTrim(cIdEst) + " inválido.")
	endif

	// Verifica se os contratos e locais do contrato existe na tabela ZC1 - Contrato e Local de contrato
	cIdCotr := oJson["sintetico"]["analitico"][nI]:GetJsonText("idcontrato")
	cLocCon := oJson["sintetico"]["analitico"][nI]:GetJsonText("idlocalcontrato")
	if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdCotr),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cLocCon),TamSX3("ZC1_LOCCTR")[1]," ")))
		lErroTenta := .T.
		Return("ANALÍTICO: O contrato " + AllTrim(cIdCotr) + " e o local do contrato " + AllTrim(cLocCon) + " não existe.")
	endif	

	cEstPre := oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("idfatura")
	if !EMPTY(cEstPre)
		cEstPre := Avkey(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("idfatura"),"ZC6_IDFATU")+;
						Avkey(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("id"),"ZC6_IDESTU")		
		// Valida chave de estorno da prévia
		ZC6->(DbSetOrder(2)) //ZC6_FILIAL+ZC6_IDFATU+ZC6_IDESTU
		if ZC6->(DbSeek(cEstPre))
			if ZC6->ZC6_PREVIA!='1'
				Return("O idfatura "+ alltrim(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("idfatura"))+;
						" e id do estudante "+ alltrim(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("id"))+; 
						" não é uma prévia. ")				
			endif	
		else
			Return("O idfatura "+ alltrim(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("idfatura"))+;
					" e id do estudante "+ alltrim(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("id"))+; 
					" da prévia não existe. ")
		endif		
		ZC6->(DbSetOrder(1))
	Endif
	
next	

// Verifica se a quantidade de TCE/TCA é maior que zero
nQtde := Val(oJson["sintetico"]:GetJsonText("quantidade_tce_tca"))
if nQtde <= 0
	Return("A quantidade de TCE/TCA deve ser maior que zero.")
endif

Return("")

/*/{Protheus.doc} GravaZc6
Realiza a gravação na tabela ZC6
@author Danilo José Grodzicki
@since 01/10/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function GravaZc6(oJson)

Local nI

Local nAnalitico := 0

//cIdFatu  := oJson["sintetico"]:GetJsonText("idfatura")
cIdFatu  := PegaIdFatu()
cLote 	 := oJson["sintetico"]:GetJsonText("lote")
cSeqLot  := oJson["sintetico"]:GetJsonText("seqlote")
cProFat  := oJson["sintetico"]:GetJsonText("processo")
cLotRas  := oJson["sintetico"]:GetJsonText("loterastreamento")
cIdCont  := oJson["sintetico"]:GetJsonText("idcontrato")
cIdLCont := oJson["sintetico"]:GetJsonText("idlocalcontrato")
cLocRem  := oJson["sintetico"]:GetJsonText("idlocalremessa")
cIdFolha := oJson["sintetico"]:GetJsonText("idfolha")
cConFat  := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")
cConCob  := oJson["sintetico"]:GetJsonText("idconfiguracaocobranca")
nQtde    := Val(oJson["sintetico"]:GetJsonText("quantidade_tce_tca"))
cTipPro  := oJson["sintetico"]:GetJsonText("tipoproduto")
nVlrTot  := Val(oJson["sintetico"]:GetJsonText("valortotal"))
cDatVen  := oJson["sintetico"]:GetJsonText("datavencimento")
cBcoFat  := oJson["sintetico"]:GetJsonText("bancofaturamento")
cMsgNot  := DecodeUTF8(oJson["sintetico"]:GetJsonText("mensagemnota"))
cNumPed  := DecodeUTF8(oJson["sintetico"]:GetJsonText("numeropedido"))
cFilFatu := U_VerFilFat(cConCob,cIdCont,cConFat) 
		
nAnalitico := Len(oJson["sintetico"]["analitico"])

Begin Transaction
	
	for nI = 1 to nAnalitico
		cIdEstu   := oJson["sintetico"]["analitico"][nI]:GetJsonText("id")
		cCpfEst   := oJson["sintetico"]["analitico"][nI]:GetJsonText("cpf")
		cNomEst   := Upper(AllTrim(DecodeUTF8(oJson["sintetico"]["analitico"][nI]:GetJsonText("nome"))))
		cNomSoc   := DecodeUTF8(oJson["sintetico"]["analitico"][nI]:GetJsonText("nomesocial"))
		cCompet   := StrTran(AllTrim(oJson["sintetico"]["analitico"][nI]:GetJsonText("competencia")),"/","")
		cTceTca   := oJson["sintetico"]["analitico"][nI]:GetJsonText("codigo_tce_tca")
		cIdCotr   := oJson["sintetico"]["analitico"][nI]:GetJsonText("idcontrato")
		cLocCon   := oJson["sintetico"]["analitico"][nI]:GetJsonText("idlocalcontrato")
		cTipFat   := oJson["sintetico"]["analitico"][nI]:GetJsonText("tipo_faturamento")
		nValor    := Val(oJson["sintetico"]["analitico"][nI]:GetJsonText("valor"))
		cPrevia   := oJson["sintetico"]["analitico"][nI]:GetJsonText("previa")
		cIdKairos := oJson["sintetico"]["analitico"][nI]:GetJsonText("idfaturakairos")

		cEstPre := oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("idfatura")
		IF !EMPTY(cEstPre)
			cEstPre := Avkey(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("idfatura"),"ZC6_IDFATU")+;
							Avkey(oJson["sintetico"]["analitico"][nI]["estorno_previa"]:GetJsonText("id"),"ZC6_IDESTU")			
		ENDIF		

//		cTipFrm := oJson["sintetico"]["analitico"][nI]["repasse"]:GetJsonText("frm")
		cTipFrm := oJson["sintetico"]["analitico"][nI]["repasse"]["frm"]:GetJsonText("tipo")
		nVlrEmp := Val(oJson["sintetico"]["analitico"][nI]["repasse"]["empresa"]:GetJsonText("valor"))
		nAutPpg := Val(oJson["sintetico"]["analitico"][nI]["repasse"]["autonomos"]:GetJsonText("percentual_pagar"))
		nAutVpg := Val(oJson["sintetico"]["analitico"][nI]["repasse"]["autonomos"]:GetJsonText("valor_pagar"))
		cAutUpg := oJson["sintetico"]["analitico"][nI]["repasse"]["autonomos"]:GetJsonText("unidade_pagar")
		nAutPrc := Val(oJson["sintetico"]["analitico"][nI]["repasse"]["autonomos"]:GetJsonText("percentual_receber"))
		nAutVrc := Val(oJson["sintetico"]["analitico"][nI]["repasse"]["autonomos"]:GetJsonText("valor_receber"))
		cAutUrc := oJson["sintetico"]["analitico"][nI]["repasse"]["autonomos"]:GetJsonText("unidade_receber")
		cAutFge := oJson["sintetico"]["analitico"][nI]["repasse"]["autonomos"]:GetJsonText("fato_gerador")		
	
//		Sleep(500)
		
		ZC6->(DbSetOrder(01))
		if ZC6->(DbSeek(Padr(AllTrim(cLote),TamSX3("ZC6_LOTE")[1]," ") + Padr(AllTrim(cSeqLot),TamSX3("ZC6_SEQLOT")[1]," ") ))
			RecLock("ZC6",.F.)
		else
			RecLock("ZC6",.T.)
		endif
			ZC6->ZC6_FILIAL := cFilFatu
			ZC6->ZC6_IDFATU := cIdFatu
			ZC6->ZC6_LOTE   := cLote
			ZC6->ZC6_SEQLOT := cSeqLot
			ZC6->ZC6_PROFAT := cProFat
			ZC6->ZC6_LOTRAS := cLotRas
			ZC6->ZC6_IDCONT := cIdCont
			ZC6->ZC6_LOCREM := cLocRem
			ZC6->ZC6_IDFOLH := cIdFolha
			ZC6->ZC6_CONFAT := cConFat
			ZC6->ZC6_CONCOB := cConCob
			ZC6->ZC6_QTDE   := nQtde
			ZC6->ZC6_TIPPRO := cTipPro
			ZC6->ZC6_VLRTOT := nVlrTot
			ZC6->ZC6_DATVEN := CTOD(cDatVen)
			ZC6->ZC6_BCOFAT := cBcoFat
			ZC6->ZC6_MSGNOT := cMsgNot
			ZC6->ZC6_IDESTU := cIdEstu
			ZC6->ZC6_CPFEST := cCpfEst
			ZC6->ZC6_NOMEST := cNomEst
			ZC6->ZC6_NOMSOC := cNomSoc
			ZC6->ZC6_COMPET := cCompet
			ZC6->ZC6_TCETCA := cTceTca
			ZC6->ZC6_LOCCON := cIdLCont
			ZC6->ZC6_TIPFAT := cTipFat
			ZC6->ZC6_VALOR  := nValor
			ZC6->ZC6_PREVIA := cPrevia
			ZC6->ZC6_ESTPRE := cEstPre
			ZC6->ZC6_TIPFRM := cTipFrm
			ZC6->ZC6_VLREMP := nVlrEmp
			ZC6->ZC6_AUTPPG := nAutPpg
			ZC6->ZC6_AUTVPG := nAutVpg
			ZC6->ZC6_AUTUPG := cAutUpg
			ZC6->ZC6_AUTPRC := nAutPrc
			ZC6->ZC6_AUTVRC := nAutVrc
			ZC6->ZC6_AUTURC := cAutUrc
			ZC6->ZC6_AUTFGE := cAutFge			
			ZC6->ZC6_IDCOTR := cIdCotr
			ZC6->ZC6_IDLCOT := cLocCon
			ZC6->ZC6_IDKAIR := cIdKairos
			ZC6->ZC6_DTINTE := Date()
			ZC6->ZC6_HRINTE := Time()
			ZC6->ZC6_JSON   := cJson
			ZC6->ZC6_STATUS := "1"  // Pendente
			ZC6->ZC6_GERZC5 := "N"  // Não gerou a ZC5
			ZC6->ZC6_NUMPED := cNumPed

		ZC6->(MsUnLock())

/*  Gravação da ZC5 está no fonte Rabbit.prw

		Sleep(500)

		ZC5->(DbSetOrder(08))
		if ZC5->(DbSeek(ZC6->ZC6_IDFATU))
			RECLOCK("ZC5",.F.)
		else
			RECLOCK("ZC5",.T.)
		endif
			ZC5->ZC5_FILIAL	:= ZC6->ZC6_FILIAL
			ZC5->ZC5_LOTE 	:= ZC6->ZC6_LOTE
			ZC5->ZC5_LOTRAS := ZC6->ZC6_LOTRAS
			ZC5->ZC5_IDFATU	:= ZC6->ZC6_IDFATU
			ZC5->ZC5_IDCONT	:= ZC6->ZC6_IDCONT
			ZC5->ZC5_CONFAT	:= ZC6->ZC6_CONFAT
			ZC5->ZC5_IDFOLH	:= ZC6->ZC6_IDFOLH
			ZC5->ZC5_CONCOB	:= ZC6->ZC6_CONCOB
			ZC5->ZC5_LOCCON := IIF(!EMPTY(ZC6->ZC6_LOCREM),ZC6->ZC6_LOCREM,ZC6->ZC6_LOCCON)
			ZC5->ZC5_MSGNOT	:= ZC6->ZC6_MSGNOT
			ZC5->ZC5_VALOR	:= 0 //Atualizado no job
			ZC5->ZC5_DATVEN	:= ZC6->ZC6_DATVEN
			ZC5->ZC5_TIPPRO	:= ZC6->ZC6_TIPPRO
			ZC5->ZC5_BCOFAT	:= cBcoFat
			ZC5->ZC5_DATA	:= DATE()	
			ZC5->ZC5_COMPET	:= ZC6->ZC6_COMPET			
			ZC5->ZC5_STATUS	:= "0"
			ZC5->ZC5_HORINI := TIME()
		ZC5->(MSUNLOCK())	
*/
	next
End Transaction

Return Nil

/*/{Protheus.doc} GRAVAZC5
Realiza a gravação na tabela ZC5
@author danilo.grodzicki
@since 25/08/2020
@version undefined
@param nRecno
@type user function
/*/
User Function GRAVAZC5(nRecno)

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][GRAVAZC5] INICIO - FATURAMENTO GERAR ZC5 - RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("ZC5")
ZC5->(DbSetOrder(08))

DbSelectArea("ZC6")
ZC6->(DbSetOrder(01))
ZC6->(DbGoTo(nRecno))

if ZC5->(DbSeek(ZC6->ZC6_IDFATU))
	RECLOCK("ZC5",.F.)
else
	RECLOCK("ZC5",.T.)
endif
	ZC5->ZC5_FILIAL	:= ZC6->ZC6_FILIAL
	ZC5->ZC5_LOTE 	:= ZC6->ZC6_LOTE
	ZC5->ZC5_LOTRAS := ZC6->ZC6_LOTRAS
	ZC5->ZC5_IDFATU	:= ZC6->ZC6_IDFATU
	ZC5->ZC5_IDCONT	:= ZC6->ZC6_IDCONT
	ZC5->ZC5_CONFAT	:= ZC6->ZC6_CONFAT
	ZC5->ZC5_IDFOLH	:= ZC6->ZC6_IDFOLH
	ZC5->ZC5_CONCOB	:= ZC6->ZC6_CONCOB
	ZC5->ZC5_LOCCON := IIF(!EMPTY(ZC6->ZC6_LOCREM),ZC6->ZC6_LOCREM,ZC6->ZC6_LOCCON)
	ZC5->ZC5_MSGNOT	:= ZC6->ZC6_MSGNOT
	ZC5->ZC5_VALOR	:= 0  // Atualizado no job
	ZC5->ZC5_DATVEN	:= ZC6->ZC6_DATVEN
	ZC5->ZC5_TIPPRO	:= ZC6->ZC6_TIPPRO
	ZC5->ZC5_BCOFAT	:= ZC6->ZC6_BCOFAT
	ZC5->ZC5_DATA	:= ZC6->ZC6_DTINTE
	ZC5->ZC5_COMPET	:= ZC6->ZC6_COMPET			
	ZC5->ZC5_STATUS	:= "0"
	ZC5->ZC5_HORINI := TIME()
ZC5->(MSUNLOCK())

TCSQLEXEC("UPDATE " + RETSQLNAME("ZC6") + " SET ZC6_GERZC5 = 'S' WHERE ZC6_IDFATU = '" + ZC6->ZC6_IDFATU + "'")

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "[GRAVAZC5] FIM - FATURAMENTO GERAR ZC5 - RECNO:" + CVALTOCHAR(nRecno))

Return

/*/{Protheus.doc} VerFilFat
Tratamento da filial de faturamento com base na configuração de cobrança
@type  Static Function
@author user
@since 09/04/2020
@version version
/*/
User Function VerFilFat(cConCob,cIdCont,cConFat)
Local cRet:= "0001" //Default filial matriz

ZC3->(DbSetOrder(1))
if ZC3->(DbSeek(xFilial("ZC3") + avkey(cConCob,"ZC3_IDCOBR") + avkey(cIdCont,"ZC3_IDCONT") + avkey(cConFat,"ZC3_IDPGTO") ))

	DbSelectarea("ZCN")
	ZCN->(DBSETORDER(1))
	IF ZCN->(DBSEEK(XFILIAL("ZCN")+ZC3->ZC3_UNRESP))
		IF !EMPTY(ZCN->ZCN_FILFAT)
			cRet:= ZCN->ZCN_FILFAT
		ENDIF	
	ENDIF

Endif
	
Return cRet

/*/{Protheus.doc} VBCOFAT
Rotina de tratamento do banco de faturamento
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
/*STATIC FUNCTION VBCOFAT(cBcoFat,nValor,cConFat,cIdCont)
default cBcoFat:= ""

if ZC4->(DbSeek(xFilial("ZC4")+cConFat+cIdCont))
	
	cBcoFat:= ZC4->ZC4_CODBCO
	
	if nValor >= ZC4->ZC4_VLREXC
		cBcoFat := IF(EMPTY(ZC4->ZC4_BCOEXC),cBcoFat,ZC4->ZC4_BCOEXC)
	endif

else

	IF EMPTY(cBcoFat)
		IF nValor > SuperGetMV("CI_VLRBCO",.T.,250)
			cBcoFat:= ALLTRIM(SuperGetMV("CI_BCOMIN",.T.,"237"))
		ELSE
			cBcoFat:= ALLTRIM(SuperGetMV("CI_BCOMAX",.T.,"341"))
		ENDIF	
	ENDIF

endif

RETURN cBcoFat*/

/*/{Protheus.doc} PegaIdFatu
Função para pegar o IdFatu
@type  Static Function
@author user
@since 09/04/2020
@version version
/*/
Static Function PegaIdFatu()

Local nI
Local cIdFatTemp

Local cIdFatura := space(19)

if At("idfatura",cJson) > 0
	cIdFatTemp := Subs(cJson,At("idfatura",cJson)+10,19)
	for nI = 1 to Len(cIdFatTemp)
		if Subs(cIdFatTemp,nI,1) $ '0123456789'
			cIdFatura += Subs(cIdFatTemp,nI,1)
		endif
	next
	cIdFatura := AllTrim(cIdFatura)
endif

Return(cIdFatura)