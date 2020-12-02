#INCLUDE "protheus.CH"
#INCLUDE "RESTFUL.CH"
#include "tbiconn.ch"

/*/{Protheus.doc} CINTK05
Serviço de integração de bolsa auxilio - PROCESSAMENTO DAS FILAS KAIROS
@type  Function
@author Luiz Enrique
@since 29/06/2020
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
USER  Function CINTK05(nRecno)
	
Local oJson		:= nil
Local lerro		:= .F.
Local cErro		:= ""
Local cLote   	:= ""
Local cSeqLot 	:= ""
Local cIdFolha	:= ""
Local cIdCont	:= ""
Local cIdLoc	:= ""
Local cmsg		:= ""

Private cJson

Private cAtivo     := "S"
Private lErroTenta := .F.
Private cNomSocial := space(150)
Private dDtEnvio   := CtoD("")

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK05] Inicio da integração bolsa auxílio RECNO:" + CVALTOCHAR(nRecno))

//Posiciona na tabela ZCQ
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
	// 	CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"[CINTK03] FIM - Serviço de integração bolsa auxílio - RECNO:" + CVALTOCHAR(nRecno))
	// 	Return
	// endif
 
	//Avalia o campo operação ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"I")

			if !Empty(cErro)	
				cmsg:=  Alltrim(cErro)
				lErro:= .T.	
			else
				GravaZc8(oJson)	
			endif		

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 

			// Valida os dados do oJson
			cErro := ValoJson(oJson,"A")

			if !Empty(cErro)	
				cmsg:=  Alltrim(cErro)
				lErro:= .T.	
			else
				GravaZc8(oJson)	
			endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

			cErro := ValoJson(oJson,"E")

			if !Empty(cErro)	
				cmsg:=  Alltrim(cErro)
				lErro:= .T.	
			else
				cLote	:= oJson["sintetico"]:GetJsonText("lote")
				cLote	:= Padr(AllTrim(cLote),TamSX3("ZC8_LOTE")[1]," ")

				cSeqLot	:= oJson["sintetico"]:GetJsonText("seqlote")
				cSeqLot	:= Padr(AllTrim(cSeqLot),TamSX3("ZC8_SLOTE")[1]," ")

				cIdFolha := oJson["sintetico"]:GetJsonText("idfolha")
				cIdFolha := Padr(AllTrim(cIdFolha),TamSX3("ZC7_IDFOL")[1]," ") 

				cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
				cIdCont := Padr(AllTrim(cIdCont),TamSX3("ZC7_IDCNTT")[1]," ")

				cIdLoc := oJson["sintetico"]:GetJsonText("idlocalcontrato")
				cIdLoc := Padr(AllTrim(cIdLoc),TamSX3("ZC7_IDLOCC")[1]," ")

				// Exclui o registro da tabela ZC8
				Begin Transaction

					while ZC8->(!eof()) .and. ZC8->(ZC8_LOTE+ZC8_SLOTE) == cLote+cSeqLot
						RecLock("ZC8",.F.)
						ZC8->(DbDelete())
						ZC8->(MsUnLock())
						ZC8->(dbSkip())	
					end
					
					dbSelectArea("ZC8")
					ZC8->(dbSetOrder(2))
					if !ZC8->(DbSeek(xFilial("ZC8") + cLote))
						dbSelectArea("ZC7")
						ZC7->(dbSetOrder(1))
						IF ZC7->(dbSeek(cIdFolha))
							RecLock("ZC7",.F.)
							ZC7->(DbDelete())
							ZC7->(MsUnLock())		

							ExcTitPBA(cIdCont, cIdLoc, cIdFolha)

						ENDIF
					ENDIF
					
				End Transaction

			Endif

	ENDCASE

	FreeObj(oJson)	 

ELSE 
	cmsg:= "JSON NÃO INFORMADO."
	lErro:= .T.
ENDIF

//Grava Status
RECLOCK("ZCQ",.F.)

	if lErro
		if lErroTenta
			ZCQ->ZCQ_QTDTEN := ZCQ->ZCQ_QTDTEN + 1
			if ZCQ->ZCQ_QTDTEN <= GetMv("CI_QTDTENT")
				// Reprocessar o registro
				ZCQ->ZCQ_STATUS := "0" 	
				ZCQ->ZCQ_CODE   := "200"
			else
				ZCQ->ZCQ_STATUS := "1" 	
				ZCQ->ZCQ_CODE   := "404"  // Erro
				ZCQ->ZCQ_MSG    := cmsg
			endif
		else
			ZCQ->ZCQ_STATUS := "1" 	
			ZCQ->ZCQ_CODE   := "404"  // Erro
			ZCQ->ZCQ_MSG    := cmsg
		endif
	else
		ZCQ->ZCQ_STATUS := "2" 	
		ZCQ->ZCQ_CODE   := "200" // Sucesso
		ZCQ->ZCQ_MSG    := "Integração realizada com sucesso"
		ZCQ->ZCQ_QTDTEN := 0
	endif

MSUNLOCK()	

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK05] Fim integração bolsa auxílio RECNO:" + CVALTOCHAR(nRecno))

RETURN

/*/{Protheus.doc} BOLSAAUXILIO
Serviço de integração de bolsa auxilio
@author felipe ruiz
@since 27/09/2019
@version 1.0
@return ${return}, ${return_description}

@type class
/*/
WSRESTFUL BOLSAAUXILIO DESCRIPTION "Serviço de integração de bolsa auxilio" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza o cadastro de bolsa auxilio";
	WSSYNTAX "/BOLSAAUXILIO"
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a atualização de bolsa auxilio";
	WSSYNTAX "/BOLSAAUXILIO"
	WSMETHOD DELETE; 
	DESCRIPTION "Realiza a exclusão de bolsa auxilio";
	WSSYNTAX "/BOLSAAUXILIO"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta de bolsa auxilio";
	WSSYNTAX "/BOLSAAUXILIO"
END WSRESTFUL

/*/{Protheus.doc} GET
Retorna dados de bolxa auxilio
@author felipe ruiz
@since 10/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
WSMETHOD GET WSSERVICE BOLSAAUXILIO

Local cLote      := ""
Local oJson      := Nil
Local cJson      := ""
Local cIdEst     := ""
Local cSeqLot    := ""
Local nTotAcre   := 0
Local nTotDesc   := 0
Local nTotBenAdi := 0

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

::SetContentType('application/json')

oJson := JsonObject():new()

oJson:fromJson(Self:GetContent(,.T.))
cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"C")
if !Empty(cErro)
	U_GrvLogKa("CINTK05", "GET", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif	

cLote	:= oJson["sintetico"]:GetJsonText("lote")
cLote	:= Padr(AllTrim(cLote),TamSX3("ZC8_LOTE")[1]," ")

cSeqLot	:= oJson["sintetico"]:GetJsonText("seqlote")
cSeqLot	:= Padr(AllTrim(cSeqLot),TamSX3("ZC8_SLOTE")[1]," ")

cIdEst 	:= oJson["sintetico"]["analitico"]:GetJsonText("id")
cIdEst	:= Padr(AllTrim(cIdEst),TamSX3("ZC8_ID")[1]," ")

cJson := '{'
cJson += ' "sintetico":{'
cJson += '	"idcontrato":' + EncodeUTF8(AllTrim(ZC7->ZC7_IDCNTT), "cp1252") + ','
cJson += '	"idlocalcontrato":' + EncodeUTF8(AllTrim(ZC7->ZC7_IDLOCC), "cp1252") + ','
cJson += '	"idconfiguracaofolha":"'+ EncodeUTF8(AllTrim(ZC7->ZC7_IDCFGF), "cp1252") + '",'
cJson += '	"competencia":"' + EncodeUTF8(AllTrim(ZC7->ZC7_COMPET), "cp1252") + '",'
cJson += '	"idfolha":' + EncodeUTF8(AllTrim(ZC8->ZC8_IDFOL), "cp1252") + ','
cJson += '	"lote":"' + EncodeUTF8(AllTrim(ZC8->ZC8_LOTE), "cp1252") + '",'
cJson += '	"seqlote":' + EncodeUTF8(AllTrim(ZC8->ZC8_SLOTE), "cp1252") + ','
cJson += '	"tipocalculo":"' + EncodeUTF8(AllTrim(ZC7->ZC7_TPCALC), "cp1252") + '",'
cJson += '	"tipofolha":"' + EncodeUTF8(AllTrim(ZC7->ZC7_TPFOL), "cp1252") + '",'
cJson += '	"quantidade":' + EncodeUTF8(cValToChar(ZC7->ZC7_QUANT), "cp1252") + ','
cJson += '	"totalgeralpagar":' + EncodeUTF8(cValToChar(ZC7->ZC7_TOTGER), "cp1252") + ','
cJson += '	"loginrede": "' + EncodeUTF8(AllTrim(ZC7->ZC7_LGREDE), "cp1252") + '",'
cJson += '	"idfatura": "' + EncodeUTF8(AllTrim(ZC7->ZC7_IDFATU), "cp1252") + '",'
cJson += '	"analitico":{'
cJson += '	    "idcontrato":' + EncodeUTF8(AllTrim(ZC8->ZC8_IDCNTT), "cp1252") + ','
cJson += '	    "idlocalcontrato":' + EncodeUTF8(AllTrim(ZC8->ZC8_IDLOCC), "cp1252") + ','
cJson += '		"numerotce":' + EncodeUTF8(AllTrim(ZC8->ZC8_NUMTCE), "cp1252") + ','
cJson += '		"id":' + EncodeUTF8(AllTrim(ZC8->ZC8_ID), "cp1252") + ','
cJson += '		"nome":"' + EncodeUTF8(AllTrim(ZC8->ZC8_NOME), "cp1252") + '",'
cJson += '		"cpf":' + EncodeUTF8(AllTrim(ZC8->ZC8_CPF), "cp1252") + ','
cJson += '		"totalpagarcalculada":' + EncodeUTF8(cValToChar(ZC8->ZC8_TCALC), "cp1252") + ','
cJson += '		"totalpagarnaocalculada":' + EncodeUTF8(cValToChar(ZC8->ZC8_TNCALC), "cp1252") + ','
cJson += '		"nomesocial":' + iif(!Empty(ZC8->ZC8_NOMSOC),'"'+EncodeUTF8(AllTrim(ZC8->ZC8_NOMSOC), "cp1252")+'"','""') + ','
cJson += '		"dataenvio":' + iif(!Empty(ZC8->ZC8_DTENVI),'"'+DtoC(ZC8->ZC8_DTENVI)+'"','""')

if ZC8->(!eof()) .and. ZC8->(ZC8_LOTE+ZC8_SLOTE+ZC8_ID) == cLote+cSeqLot+cIdEst
	cJson += ','
endif

while ZC8->(!eof()) .and. ZC8->(ZC8_LOTE+ZC8_SLOTE+ZC8_ID) == cLote+cSeqLot+cIdEst
	
	//Bolsa Auxilio
	if ZC8->ZC8_TIPO == '1'
		cJson += '		"bolsaauxilio":{'		
		cJson += '			"valorcontratual":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLCONT), "cp1252") + ','
		cJson += '			"valorpagar":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLPAG), "cp1252") + ''
		cJson += '		},'
	endif
	
	//Auxilio transporte
	if ZC8->ZC8_TIPO == '2'
		cJson += '		"auxiliotransporte":{'		
		cJson += '			"valorcontratual":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLCONT), "cp1252") + ','
		cJson += '			"valorpagar":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLPAG), "cp1252") + ''
		cJson += '		},'
	endif	

	//Beneficios adicionais
	if ZC8->ZC8_TIPO == '3'
	
		cJson += '		"beneficiosadicionais":['
		
		while ZC8->(!eof()) .and. ZC8->(ZC8_LOTE+ZC8_SLOTE+ZC8_ID) == cLote+cSeqLot+cIdEst .and. ZC8->ZC8_TIPO == '3'
			
			nTotBenAdi+= ZC8->ZC8_VLCONT
			nTotBenAdi+= ZC8->ZC8_VLPAG
			
			cJson += '		{'
			cJson += '			"tipo":' + EncodeUTF8(cValToChar(ZC8->ZC8_TPKAI), "cp1252") + ','
			cJson += '			"descricao":"' + EncodeUTF8(ALLTRIM(ZC8->ZC8_DESCRI), "cp1252") + '",'		
			cJson += '			"valorcontratual":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLCONT), "cp1252") + ','
			cJson += '			"valorpagar":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLPAG), "cp1252") + ''
			
			ZC8->(dbSkip())
			
			IF ZC8->ZC8_TIPO == '3'
				cJson += '	},'
			ELSE
				cJson += '	}'
			ENDIF

		enddo
		
		cJson += '],'
		cJson += '"totalbeneficiosadicionais":' + EncodeUTF8(cValToChar(nTotBenAdi), "cp1252")
	endif

	if ZC8->ZC8_TIPO == '4' .or. ZC8->ZC8_TIPO == '5'
		cJson += ','
	endif
	
	//Detalhes
	if ZC8->ZC8_TIPO == '4' .or. ZC8->ZC8_TIPO == '5'
		
		cJson += '		"detalhes":{'		
		
		if ZC8->ZC8_TIPO == '4'
			cJson += '			"acrescimo":['
			nTotAcre:= ZC8->ZC8_TOACRE
			while ZC8->(!eof()) .and. ZC8->(ZC8_LOTE+ZC8_SLOTE+ZC8_ID) == cLote+cSeqLot+cIdEst .and. ZC8->ZC8_TIPO == '4'
				
	
				cJson += '		{'
				cJson += '			"tipo":' + EncodeUTF8(cValToChar(ZC8->ZC8_TPKAI), "cp1252") + ','
				cJson += '			"descricao":"' + EncodeUTF8(ALLTRIM(ZC8->ZC8_DESCRI), "cp1252") + '",'		
				cJson += '			"valor":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLPAG), "cp1252") + ''
				
				ZC8->(dbSkip())
				
				IF ZC8->ZC8_TIPO == '4'
					cJson += '	},'
				ELSE
					cJson += '	}'
				ENDIF
	
			enddo
			
			cJson += '],'
		endif

		if ZC8->ZC8_TIPO == '5'
			cJson += '			"desconto":['
			
			nTotDesc:= ZC8->ZC8_TODESC

			while ZC8->(!eof()) .and. ZC8->(ZC8_LOTE+ZC8_SLOTE+ZC8_ID) == cLote+cSeqLot+cIdEst .and. ZC8->ZC8_TIPO == '5'
				
				cJson += '		{'
				cJson += '			"tipobeneficio":' + EncodeUTF8(ALLTRIM(ZC8->ZC8_TPBNF), "cp1252") + ','
				cJson += '			"descricaobeneficio":' + EncodeUTF8(ALLTRIM(ZC8->ZC8_DSCBNF), "cp1252") + ','
				cJson += '			"tipo":' + EncodeUTF8(cValToChar(ZC8->ZC8_TPKAI), "cp1252") + ','
				cJson += '			"descricao":"' + EncodeUTF8(ALLTRIM(ZC8->ZC8_DESCRI), "cp1252") + '",'		
				cJson += '			"valor":' + EncodeUTF8(cValToChar(ZC8->ZC8_VLPAG), "cp1252") + ','
				cJson += '			"motivo":"' + EncodeUTF8(ALLTRIM(ZC8->ZC8_MOTIVO), "cp1252") + '"'
				
				ZC8->(dbSkip())
				
				IF ZC8->ZC8_TIPO == '5'
					cJson += '	},'
				ELSE
					cJson += '	}'
				ENDIF
	
			enddo
			
			cJson += '],'
		endif		
		
		cJson += '	 "totalacrescimos":' + EncodeUTF8(cValToChar(nTotAcre), "cp1252") + ','
		cJson += '	 "totaldescontos":' + EncodeUTF8(cValToChar(nTotDesc), "cp1252") 		
		
		cJson += '}'
		
	endif

	ZC8->(dbSkip())		
enddo	

cJson += '	}'
cJson += ' }'
cJson += '}'

::SetResponse(cJson)
	
Return .T.


/*/{Protheus.doc} POST
Realiza o cadastro de bolsa auxilio
@author felipe ruiz
@since 27/09/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
WSMETHOD POST WSSERVICE BOLSAAUXILIO

local oJson
local cErro := ''

Private cJson      := ""
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""
Private cAtivo     := "S"
Private cNomSocial := space(150)
Private dDtEnvio   := CtoD("")

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"I")
if !Empty(cErro)
	U_GrvLogKa("CINTK05", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

//objeto com dados, inclusao ou alteração, deletar
GravaZc8(oJson)

U_GrvLogKa("CINTK05", "POST", "1", "Integração realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integração realizada com sucesso")

/*/{Protheus.doc} PUT
	Função rest responsavel por receber atualização
@author felipe ruiz
@since 17/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
WSMETHOD PUT WSSERVICE BOLSAAUXILIO

local oJson
local cErro := ''

Private cJson      := ""
Private dDtIniInt  := Date()
Private cHrIniInt  := Time()
Private cHrIniDw3  := ""
Private cHrFimDw3  := ""
Private cAtivo     := "S"
Private cNomSocial := space(150)
Private dDtEnvio   := CtoD("")

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"A")
if !Empty(cErro)
	U_GrvLogKa("CINTK05", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

//objeto com dados, inclusao ou alteração, deletar
GravaZc8(oJson)

U_GrvLogKa("CINTK05", "PUT", "1", "Alteração realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Alteração realizada com sucesso")

/*/{Protheus.doc} DELETE
	Funçã rest responsavel por deletar bolsa auxilio
@author felipe ruiz
@since 17/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
WSMETHOD DELETE WSSERVICE BOLSAAUXILIO

Local oJson
//Local cTab

Local cLote   := ""
Local cSeqLot := ""

Private cJson     := ""
Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

::SetContentType('application/json')

oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))

cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"E")
if !Empty(cErro)
	U_GrvLogKa("CINTK05", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif	

cLote	:= oJson["sintetico"]:GetJsonText("lote")
cLote	:= Padr(AllTrim(cLote),TamSX3("ZC8_LOTE")[1]," ")

cSeqLot	:= oJson["sintetico"]:GetJsonText("seqlote")
cSeqLot	:= Padr(AllTrim(cSeqLot),TamSX3("ZC8_SLOTE")[1]," ")

cIdFolha := oJson["sintetico"]:GetJsonText("idfolha")
cIdFolha := Padr(AllTrim(cIdFolha),TamSX3("ZC7_IDFOL")[1]," ") 

cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
cIdCont := Padr(AllTrim(cIdCont),TamSX3("ZC7_IDCNTT")[1]," ")

cIdLoc := oJson["sintetico"]:GetJsonText("idlocalcontrato")
cIdLoc := Padr(AllTrim(cIdLoc),TamSX3("ZC7_IDLOCC")[1]," ")

// Exclui o registro da tabela ZC8
Begin Transaction
	while ZC8->(!eof()) .and. ZC8->(ZC8_LOTE+ZC8_SLOTE) == cLote+cSeqLot
		RecLock("ZC8",.F.)
			ZC8->(DbDelete())
		ZC8->(MsUnLock())
	ZC8->(dbSkip())	
	end
	
	dbSelectArea("ZC8")
	ZC8->(dbSetOrder(2))
	if !ZC8->(DbSeek(xFilial("ZC8") + cLote))
		dbSelectArea("ZC7")
		ZC7->(dbSetOrder(1))
		IF ZC7->(dbSeek(cIdFolha))

			RecLock("ZC7",.F.)
				ZC7->(DbDelete())
			ZC7->(MsUnLock())		

			ExcTitPBA(cIdCont, cIdLoc, cIdFolha)

		ENDIF
	ENDIF		

End Transaction

U_GrvLogKa("CINTK05", "DELETE", "1", "Exclusao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Exclusao realizada com sucesso")	

/*/{Protheus.doc} ValoJson
	Valida Json
@author felipe ruiz
@since 17/10/2019
@version 1.0
@return ${return}, ${return_description}
@param oJson, object, descricao
@param cTipo, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

Local cTab

Local cLote		:= ""
Local cSeqLot	:= ""
Local cIdCont 	:= ""
Local cIdLoc	:= ""
Local cCompet	:= ""
Local cIdFolha	:= ""
Local cIdEst 	:= ""
Local cNumTce   := ""

// Verifica se enviou o lote de folha
cLote := oJson["sintetico"]:GetJsonText("lote")
if Empty(cLote)
	Return("O lote de folha é obrigatorio.")
endif

// Verifica se enviou a sequencia do lote de folha
cSeqLot := oJson["sintetico"]:GetJsonText("seqlote")
if Empty(cSeqLot)
	Return("A sequencia do lote é obrigatorio.")
endif

if cTipo == "E" .or. cTipo == "C"  // Exclusão ou Consulta

	// Verifica se já existe o lote e sequencia do lote cadastrado
	dbSelectArea("ZC8")
	ZC8->(dbSetOrder(2))	
	if !ZC8->(DbSeek(xFilial("ZC8") + Padr(AllTrim(cLote),TamSX3("ZC8_LOTE")[1]," ") + Padr(AllTrim(cSeqLot),TamSX3("ZC8_SLOTE")[1]," ") ))
		Return("O lote " + AllTrim(cLote) + " e sequencia do lote " + AllTrim(cSeqLot) + " não existe.")
	endif
	
	dbSelectArea("ZC7")
	ZC7->(dbSetOrder(1))
	ZC7->(dbSeek(ZC8->ZC8_IDFOL))		
	
	if cTipo == "E"  // Exclusão
		// Verifica se o status da folha está como processar
		if ZC7->ZC7_STATUS != "1"
			Return("A folha está com status de processamento, exclusão não permitida.")
		endif

		// Pega ID de folha
		cIdFolha := oJson["sintetico"]:GetJsonText("idfolha")

		// Pega ID do contrato
		cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
		
		// Pega ID do local do contrato
		cIdLoc := oJson["sintetico"]:GetJsonText("idlocalcontrato")

		cTab := GetNextAlias()
		BeginSql alias cTab
			SELECT * FROM %TABLE:SE1% SE1			 		 	
			WHERE E1_FILIAL=%xfilial:SE1%
				AND E1_TIPO =  'PBA'
				AND E1_PREFIXO = 'PBA'
				AND E1_XIDCNT = %Exp:cIdCont%
				AND E1_XIDLOC = %Exp:cIdLoc%
				AND E1_XIDFOLH = %Exp:cIdFolha%
				AND SE1.D_E_L_E_T_=''
		EndSql
		(cTab)->(DbGoTop())
		if (cTab)->(!Eof())
			IF (cTab)->E1_SALDO < (cTab)->E1_VALOR
				(cTab)->(DbCloseArea())
				Return("Já foi realizado o fechamento financeiro para está folha, alteração não permitida.")
			ENDIF	
		endif
		(cTab)->(DbCloseArea())

	endif

endif

// Verifica se enviou o ID de folha
cIdFolha := oJson["sintetico"]:GetJsonText("idfolha")
if Empty(cIdFolha)
	Return("O ID da folha é obrigatório.")	
endif

// Verifica se enviou o ID do contrato
cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")

// Verifica se enviou o ID do local do contrato
cIdLoc := oJson["sintetico"]:GetJsonText("idlocalcontrato")

dbSelectArea("ZC0")
ZC0->(dbSetOrder(1))
if !ZC0->(DbSeek(xFilial("ZC0") + Padr(AllTrim(cIdCont),TamSX3("ZC0_CODIGO")[1]," ")))
	lErroTenta := .T.
	Return("O contrato " + AllTrim(cIdCont) + " não existe.")
endif

// Verifica se o contrato e o local do contrato já está cadastrado
dbSelectArea("ZC1")
ZC1->(dbSetOrder(1))	
if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdCont),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cIdLoc),TamSX3("ZC1_LOCCTR")[1]," ")))
	lErroTenta := .T.
	Return("O contrato " + AllTrim(cIdCont) + " e o local do contrato " + AllTrim(cIdLoc) + " não existe.")
endif

cIdCfgFol := oJson["sintetico"]:GetJsonText("idconfiguracaofolha")
if !Empty(cIdCfgFol)
	// Verifica se a configuração da folha existe na tabela ZC2
	dbSelectArea("ZC2")
	ZC2->(dbSetOrder(1))		
	if !ZC2->(DbSeek(xFilial("ZC2") + Padr(AllTrim(cIdCfgFol),TamSX3("ZC2_IDFOLH")[1]," ") ))
		lErroTenta := .T.
		Return("A configuração da folha " + AllTrim(cIdCfgFol) + " não existe.")
	endif
	// Verificar se existe contrato e local de contrato cadastrado para a configuração de folha.
	//if !ZCB->(DbSeek(xFilial("ZCB") + Padr(AllTrim(cIdCfgFol),TamSX3("ZC2_IDFOLH")[1]," ") ))
	//	Return("Não foram encontrados locais de contratos para a configuração da folha " + AllTrim(cIdCfgFol) + ".")
	//endif
else
	Return("A configuração da folha é obrigatoria.")			
endif

// Valida se a competencia está preenchida
cCompet := oJson["sintetico"]:GetJsonText("competencia")
if Empty(cCompet) 
	Return("A competencia da folha é obrigatoria.")
endif

cTpCalc:= AllTrim(oJson["sintetico"]:GetJsonText("tipocalculo"))
if Empty(cTpCalc) .or. !(cTpCalc $ "123")
	Return("Tipo de calculo da folha " + cTpCalc + " inválido.")
endif

if cTpCalc == "1"
	nTotPgnCalc	:= val(oJson["sintetico"]["analitico"]:GetJsonText("totalpagarnaocalculada"))
//		if nTotPgnCalc == 0
//			Return("Para o tipo de calculo gerencial é obrigatório informar o valor total a pagar não calculado.")
//		endif	
elseif cTpCalc == "2"
	nTotPgCalc	:= val(oJson["sintetico"]["analitico"]:GetJsonText("totalpagarcalculada"))
//		if nTotPgCalc == 0
//			Return("Para o tipo de calculo padrão é obrigatório informar o valor total a pagar calculado.")
//		endif			
endif	

// Verifica id do estudante
cIdEst := oJson["sintetico"]["analitico"]:GetJsonText("id")
if Empty(cIdEst)
	Return("Id estudante " + AllTrim(cIdEst) + " inválido.")
endif

// Verifica número do TCE
cNumTce := oJson["sintetico"]["analitico"]:GetJsonText("numerotce")
if Empty(cNumTce)
	Return("Número do TCE " + AllTrim(cNumTce) + " inválido.")
endif

// Verifica se existe o id do TCE cadastrado
SRA->(DbOrderNickName("IDTCETCA01"))
if !SRA->(DbSeek(xFilial("SRA") + Padr(AllTrim(cNumTce),TamSX3("RA_XID")[1]," ") ))
	lErroTenta := .T.
	Return("O número do TCE " + AllTrim(cNumTce) + " não existe.")
else
	// Verifica se os dados bancários estão preenchidos
	if SRA->RA_XORDPGT = "N"  // Não gera ordem de pagamento
		if Empty(SRA->RA_BCDEPSA)
			//Return("O banco e a agência para depósito do salário é obrigatório.")
			cAtivo  := "N"
		endif
//		if Empty(SRA->RA_XDIGAG)
			//Return("O dígito da agência bancária é obrigatório.")
//			cAtivo  := "N"
//		endif
		if Empty(SRA->RA_CTDEPSA)
			//Return("A conta depósito de salário é obrigatório.")
			cAtivo  := "N"
		endif
		if Empty(SRA->RA_XDIGCON)
			//Return("O dígito de controle da conta depósito de salário é obrigatório.")
			cAtivo  := "N"
		endif
	endif
endif		

Return("")

/*/{Protheus.doc} GravaZc8
Processa dados para gravação de inclusao, atualização e delete
@author felipe ruiz
@since 17/10/2019
@version 1.0
@return ${return}, ${return_description}
@param oJson, object, descricao
@param cTipo, characters, descricao
@type function
/*/
static function GravaZc8(oJson)

//Local cTab
//Local cNumMov
Local cTipo

Local cLote       := oJson["sintetico"]:GetJsonText("lote")
Local cSeqLot     := oJson["sintetico"]:GetJsonText("seqlote")
Local cIdCont     := oJson["sintetico"]:GetJsonText("idcontrato")
Local cIdLoc      := oJson["sintetico"]:GetJsonText("idlocalcontrato")
//Local cIdCfgFol   := oJson["sintetico"]:GetJsonText("idconfiguracaofolha")
//Local cCompet     := oJson["sintetico"]:GetJsonText("competencia")
Local cIdFolha    := oJson["sintetico"]:GetJsonText("idfolha")
//Local cTpCalc     := oJson["sintetico"]:GetJsonText("tipocalculo")
//Local cTpFol      := oJson["sintetico"]:GetJsonText("tipofolha")
//Local nQuant      := val(oJson["sintetico"]:GetJsonText("quantidade"))
//Local nTotGer     := val(oJson["sintetico"]:GetJsonText("totalgeralpagar"))
//Local cLgRede     := oJson["sintetico"]:GetJsonText("loginrede")
Local cNumTce     := oJson["sintetico"]["analitico"]:GetJsonText("numerotce")
Local cIdEst      := oJson["sintetico"]["analitico"]:GetJsonText("id")
Local cNome       := Upper(AllTrim(DecodeUTF8(oJson["sintetico"]["analitico"]:GetJsonText("nome"))))
Local cCpf        := oJson["sintetico"]["analitico"]:GetJsonText("cpf")
Local nTotPgCalc  := val(oJson["sintetico"]["analitico"]:GetJsonText("totalpagarcalculada"))
Local nTotPgnCalc := val(oJson["sintetico"]["analitico"]:GetJsonText("totalpagarnaocalculada"))
Local nTotAcre    := val(oJson["sintetico"]["analitico"]["detalhes"]:GetJsonText("totalacrescimos"))
Local nTotDesc    := val(oJson["sintetico"]["analitico"]["detalhes"]:GetJsonText("totaldescontos"))
Local cIdCntIt    := oJson["sintetico"]["analitico"]:GetJsonText("idcontrato")
Local cIdLocIt    := oJson["sintetico"]["analitico"]:GetJsonText("idlocalcontrato")
Local cNomSocial  := oJson["sintetico"]["analitico"]:GetJsonText("nomesocial")
Local dDtEnvio    := CtoD(AllTrim(oJson["sintetico"]["analitico"]:GetJsonText("dataenvio")))
Local aDados      := {}
local nI          := 0
Local cTipVba     := ""
Local cIdKairos   := " "
Local cIdFatu     := " "

cNomSocial := oJson["sintetico"]["analitico"]:GetJsonText("nomesocial")
dDtEnvio   := CtoD(AllTrim(oJson["sintetico"]["analitico"]:GetJsonText("dataenvio")))

SRA->(DbOrderNickName("IDTCETCA01"))
if SRA->(DbSeek(xFilial("SRA") + Padr(AllTrim(cNumTce),TamSX3("RA_XID")[1]," ") ))
	cCpf := SRA->RA_CIC
endif

// Pega o Id do Kairós
cIdKairos := oJson["sintetico"]:GetJsonText("idfolhakairos")

// Pega o Id do faturamento
cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")

//Bolsa auxilio
AADD(aDados,{"1",;
			 "Bolsa auxilio",;
			 val(oJson["sintetico"]["analitico"]["bolsaauxilio"]:GetJsonText("valorcontratual")),;
			 val(oJson["sintetico"]["analitico"]["bolsaauxilio"]:GetJsonText("valorpagar")),;
			 "BAX",; //Fixo na tabela de verbas
			 "",;
			 "",;
			 "";
			 })
			 
//Auxilio transporte
AADD(aDados,{"2",;
			 "Auxilio transporte",;
			 val(oJson["sintetico"]["analitico"]["auxiliotransporte"]:GetJsonText("valorcontratual")),;
			 val(oJson["sintetico"]["analitico"]["auxiliotransporte"]:GetJsonText("valorpagar")),;
			 "ATR",; //Fixo na tabela de verbas 
			 "",;
			 "",;
			 "";
			 })			 

for nI:= 1 to Len(oJson["sintetico"]["analitico"]["beneficiosadicionais"])
	//Beneficios adicionais
	AADD(aDados,{"3",;
				DecodeUTF8(oJson["sintetico"]["analitico"]["beneficiosadicionais"][nI]:GetJsonText("descricao")),;
				val(oJson["sintetico"]["analitico"]["beneficiosadicionais"][nI]:GetJsonText("valorcontratual")),;
				val(oJson["sintetico"]["analitico"]["beneficiosadicionais"][nI]:GetJsonText("valorpagar")),;
				oJson["sintetico"]["analitico"]["beneficiosadicionais"][nI]:GetJsonText("tipo"),;
				"",;
				"",;
				"";
				})
next

for nI:= 1 to Len(oJson["sintetico"]["analitico"]["detalhes"]["acrescimo"])
	cTipVba:= oJson["sintetico"]["analitico"]["detalhes"]["acrescimo"][nI]:GetJsonText("tipo")
	//Acrescimos
	if !empty(cTipVba)
		AADD(aDados,{"4",;
					DecodeUTF8(oJson["sintetico"]["analitico"]["detalhes"]["acrescimo"][nI]:GetJsonText("descricao")),;
					0,;
					val(oJson["sintetico"]["analitico"]["detalhes"]["acrescimo"][nI]:GetJsonText("valor")),;
					cTipVba,;
					"",;
					"",;
					"";
					})	
	endif			 		 	
next

for nI:= 1 to Len(oJson["sintetico"]["analitico"]["detalhes"]["desconto"])
	cTipVba:= oJson["sintetico"]["analitico"]["detalhes"]["desconto"][nI]:GetJsonText("tipo")
	//Descontos
	if !empty(cTipVba)
		AADD(aDados,{"5",;
					DecodeUTF8(oJson["sintetico"]["analitico"]["detalhes"]["desconto"][nI]:GetJsonText("descricao")),;
					0,;
					val(oJson["sintetico"]["analitico"]["detalhes"]["desconto"][nI]:GetJsonText("valor")),;
					cTipVba,;
					oJson["sintetico"]["analitico"]["detalhes"]["desconto"][nI]:GetJsonText("motivo"),;
					oJson["sintetico"]["analitico"]["detalhes"]["desconto"][nI]:GetJsonText("tipobeneficio"),;
					DecodeUTF8(oJson["sintetico"]["analitico"]["detalhes"]["desconto"][nI]:GetJsonText("descricaobeneficio"));
					})	
	endif			 	
next

cIdFolha := Padr(AllTrim(cIdFolha),TamSX3("ZC7_IDFOL")[1]," ")

dbSelectArea("ZC8")
ZC8->(dbSetOrder(2))	
if ZC8->(DbSeek(xFilial("ZC8") + Padr(AllTrim(cLote),TamSX3("ZC8_LOTE")[1]," ") + Padr(AllTrim(cSeqLot),TamSX3("ZC8_SLOTE")[1]," ") ))
	cTipo := "A"
else
	cTipo := "I"
endif

//if cTipo == "A"
if ZC8->(DbSeek(xFilial("ZC8") + Padr(AllTrim(cLote),TamSX3("ZC8_LOTE")[1]," ") + Padr(AllTrim(cSeqLot),TamSX3("ZC8_SLOTE")[1]," ") ))

	TCSQLEXEC("UPDATE "+RETSQLNAME("ZC8")+ " SET D_E_L_E_T_='*',R_E_C_D_E_L_=R_E_C_N_O_ WHERE ZC8_LOTE='"+cLote;
			  +"' AND ZC8_SLOTE='"+cSeqLot+"' AND ZC8_ID='"+cIdEst+"'")		

	dbSelectArea("ZC8")
	ZC8->(dbSetOrder(2))
	if !ZC8->(DbSeek(xFilial("ZC8") + Padr(AllTrim(cLote),TamSX3("ZC8_LOTE")[1]," ")))
		dbSelectArea("ZC7")
		ZC7->(dbSetOrder(1))
		IF ZC7->(dbSeek(cIdFolha))
			
			RecLock("ZC7",.F.)
			ZC7->(DbDelete())
			ZC7->(MsUnLock())	

			ExcTitPBA(cIdCont, cIdLoc, cIdFolha)

		ENDIF		
	endif

endif

begin transaction

/*  Gravação da ZC& está no fonte Rabbit.prw
//	Sleep(500)
	Sleep( Randomize(1000,5000) )
	
	dbSelectArea("ZC7")
	ZC7->(dbSetOrder(1))
//	IF !ZC7->(dbSeek(cIdFolha))
	IF !ZC7->(MsSeek(cIdFolha))
		cTipo := "I"
		recLock("ZC7",.T.)
			ZC7->ZC7_FILIAL	:= xFilial("ZC7")				
			ZC7->ZC7_IDCNTT	:= cIdCont
			ZC7->ZC7_IDLOCC	:= cIdLoc
			ZC7->ZC7_COMPET	:= cCompet
			ZC7->ZC7_IDFOL	:= cIdFolha
			ZC7->ZC7_TPCALC	:= cTpCalc
			ZC7->ZC7_TPFOL	:= cTpFol	
			ZC7->ZC7_QUANT	:= nQuant
			ZC7->ZC7_TOTGER	:= nTotGer
			ZC7->ZC7_IDCFGF	:= cIdCfgFol
			ZC7->ZC7_LGREDE	:= cLgRede
			ZC7->ZC7_IDFATU := cIdFatu
			ZC7->ZC7_DTINTE := Date()
			ZC7->ZC7_HRINTE := Time()
			ZC7->ZC7_JSON   := cJson
			ZC7->ZC7_STATUS	:= "1" // Aguardando identificação		
		ZC7->(msUnLock())

		IncTitPBA(cIdCont, cIdLoc, cIdFolha, cCompet , nTotGer)
	ENDIF
*/

	for nI:= 1 to Len(aDados)
		recLock("ZC8",.T.)
			ZC8->ZC8_FILIAL	:= xFilial("ZC8")
			ZC8->ZC8_IDFOL	:= cIdFolha
			ZC8->ZC8_NUMTCE	:= cNumTce
			ZC8->ZC8_ID		:= cIdEst
			ZC8->ZC8_NOME	:= cNome
			ZC8->ZC8_CPF	:= cCpf
			ZC8->ZC8_TCALC	:= nTotPgCalc
			ZC8->ZC8_TNCALC	:= nTotPgnCalc		
			ZC8->ZC8_TIPO	:= aDados[nI][1]
			ZC8->ZC8_DESCRI := aDados[nI][2]
			ZC8->ZC8_VLCONT	:= aDados[nI][3]
			ZC8->ZC8_VLPAG	:= aDados[nI][4]
			ZC8->ZC8_TPKAI	:= aDados[nI][5]
			ZC8->ZC8_MOTIVO	:= aDados[nI][6]
			ZC8->ZC8_TPBNF	:= aDados[nI][7]
			ZC8->ZC8_DSCBNF	:= aDados[nI][8]
			ZC8->ZC8_TOACRE	:= nTotAcre
			ZC8->ZC8_TODESC	:= nTotDesc			
			ZC8->ZC8_LOTE	:= cLote
			ZC8->ZC8_SLOTE	:= cSeqLot	
			ZC8->ZC8_DTINTE := Date()
			ZC8->ZC8_HRINTE := Time()
			ZC8->ZC8_JSON   := cJson
			ZC8->ZC8_IDCNTT := cIdCntIt
			ZC8->ZC8_IDLOCC := cIdLocIt
			ZC8->ZC8_IDKAIR := cIdKairos
			ZC8->ZC8_GERZC7 := "N"  // Não gerou a ZC7
			ZC8->ZC8_NOMSOC := cNomSocial
			ZC8->ZC8_DTENVI := dDtEnvio
 		ZC8->(msUnLock())
					
	next

	if cTipo == "I" //Somente na inclusão 
		SRA->(DbOrderNickName("IDTCETCA01"))
		if SRA->(DbSeek(xFilial("SRA") + Padr(AllTrim(cNumTce),TamSX3("RA_XID")[1]," ") ))
			recLock("SRA",.F.)
				SRA->RA_XATIVO  := cAtivo
				SRA->RA_XDEATIV := IIF(ALLTRIM(cAtivo)=="S","","Conta p/depósito não informada ou incompleta!")
			SRA->(msUnLock())	
		endif	
	endif

end transaction

return

/*/{Protheus.doc} GRAVAZC7
Realiza a gravação na tabela ZC7
@author danilo.grodzicki
@since 25/08/2020
@version undefined
@param nRecno
@type user function
/*/
User Function GRAVAZC7(nRecno)

Local cJson
Local cIdLoc
Local cIdCont
Local cCompet
Local nTotGer
Local cIdFatu

Local oJson := Nil

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][GRAVAZC7] INICIO - BOLSA AUXILIO GERAR ZC7 - RECNO:" + CVALTOCHAR(nRecno))

DbSelectArea("ZC7")
ZC7->(DbSetOrder(01))

DbSelectArea("ZC8")
ZC8->(DbSetOrder(01))
ZC8->(DbGoTo(nRecno))

cIdFatu := " "
oJson   := Nil
cJson   := ZC8->ZC8_JSON
oJson   := JsonObject():new()

oJson:fromJson(ZC8->ZC8_JSON)   

if !ZC7->(DbSeek(ZC8->ZC8_IDFOL))
	
	cIdFatu := oJson["sintetico"]:GetJsonText("idfatura")
	cIdCont := oJson["sintetico"]:GetJsonText("idcontrato")
	cIdLoc  := oJson["sintetico"]:GetJsonText("idlocalcontrato")
	cCompet := oJson["sintetico"]:GetJsonText("competencia")
	nTotGer := Val(oJson["sintetico"]:GetJsonText("totalgeralpagar"))

	RECLOCK("ZC7",.T.)
		ZC7->ZC7_FILIAL	:= xFilial("ZC7")				
		ZC7->ZC7_IDCNTT	:= cIdCont
		ZC7->ZC7_IDLOCC	:= cIdLoc
		ZC7->ZC7_COMPET	:= cCompet
		ZC7->ZC7_IDFOL	:= ZC8->ZC8_IDFOL
		ZC7->ZC7_TPCALC	:= oJson["sintetico"]:GetJsonText("tipocalculo")
		ZC7->ZC7_TPFOL	:= oJson["sintetico"]:GetJsonText("tipofolha")
		ZC7->ZC7_QUANT	:= Val(oJson["sintetico"]:GetJsonText("quantidade"))
		ZC7->ZC7_TOTGER	:= nTotGer
		ZC7->ZC7_IDCFGF	:= oJson["sintetico"]:GetJsonText("idconfiguracaofolha")
		ZC7->ZC7_LGREDE	:= oJson["sintetico"]:GetJsonText("loginrede")
		ZC7->ZC7_IDFATU := cIdFatu
		ZC7->ZC7_DTINTE := ZC8->ZC8_DTINTE
		ZC7->ZC7_HRINTE := ZC8->ZC8_HRINTE
		ZC7->ZC7_JSON   := cJson
		ZC7->ZC7_STATUS	:= "1" // Aguardando identificação		
	ZC7->(MSUNLOCK())
	
	U_INTITPBA(cIdCont, cIdLoc, ZC8->ZC8_IDFOL, cCompet, nTotGer)
	
endif

TCSQLEXEC("UPDATE " + RETSQLNAME("ZC8") + " SET ZC8_GERZC7 = 'S' WHERE ZC8_IDFOL = '" + ZC8->ZC8_IDFOL + "'")

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][GRAVAZC7] FIM - BOLSA AUXILIO GERAR ZC7 - RECNO:" + CVALTOCHAR(nRecno))

Return

/*/{Protheus.doc} INTITPBA
Inclui titulo a receber da folha para compensação dos créditos não identificados
@author carlos.henrique
@since 06/06/2019
@version undefined
@type user function
/*/
User Function INTITPBA(_cContra, _cLocCtr, _cIdFolh, _cCompet, _nValTit)
Local _cTabNum := ""
Local _cNumTit := ""
Local aCliTit  := {}
Local aLogCli  := {}
Local _cTipTit := "PBA"
Local _cPrefixo:= "PBA"

IF U_CJBKCLI(@aCliTit, _cContra, _cLocCtr, @aLogCli)

    _cTabNum:= GetNextAlias()

    BeginSql Alias _cTabNum
        SELECT MAX(E1_NUM) AS NUM 
        FROM %TABLE:SE1% SE1			 		 	
        WHERE E1_FILIAL=%xfilial:SE1%
            AND E1_TIPO =  %Exp:_cTipTit%
            AND E1_PREFIXO = %Exp:_cPrefixo%
            AND SE1.D_E_L_E_T_=''	
    EndSql

    _cNumTit := SOMA1((_cTabNum)->NUM)

    (_cTabNum)->(dbCloseArea())

    SA1->(dbSetOrder(1))
    SA1->(dbSeek(xFilial("SA1")+ aCliTit[1] + aCliTit[2] ))	

    RecLock("SE1",.T.)
        SE1->E1_FILIAL    := xFilial("SE1")
        SE1->E1_PREFIXO   := _cPrefixo
        SE1->E1_NUM       := _cNumTit
        SE1->E1_PARCELA   := "   "
        SE1->E1_TIPO      := _cTipTit
        SE1->E1_CLIENTE   := SA1->A1_COD
        SE1->E1_LOJA      := SA1->A1_LOJA
        SE1->E1_NOMCLI    := SA1->A1_NREDUZ
        SE1->E1_EMIS1     := DDATABASE
        SE1->E1_EMISSAO   := DDATABASE
        SE1->E1_VENCTO    := DDATABASE
        SE1->E1_VENCREA   := DDATABASE
        SE1->E1_VENCORI   := DDATABASE
        SE1->E1_VALOR     := _nValTit
        SE1->E1_MOEDA     := 1
        SE1->E1_SALDO     := SE1->E1_VALOR
        SE1->E1_NATUREZ   := SA1->A1_NATUREZ
        SE1->E1_VLCRUZ    := _nValTit
        SE1->E1_ORIGEM    := "CINTK05"
        SE1->E1_FLUXO     := "N"
        SE1->E1_FILORIG	  := cFilAnt
        SE1->E1_XIDCNT	  := _cContra
        SE1->E1_XIDLOC	  := _cLocCtr
		SE1->E1_XIDFOLH	  := _cIdFolh
		SE1->E1_XCOMPET	  := _cCompet
    MsUnlock()

    FaAvalSE1(1,"CINTK05")
ELSE
	RECLOCK("ZC7",.F.)
	ZC7->ZC7_LOGCOM:= aLogCli[2]
	MSUNLOCK()
ENDIF

Return

/*/{Protheus.doc} ExcTitPBA
Excluí titulo a receber da folha 
@author carlos.henrique
@since 06/06/2019
@version undefined
@type function
/*/
Static Function ExcTitPBA(_cContra, _cLocCtr, _cIdFolh)
Local _cTabDel:= GetNextAlias()
Local _cTipTit := "PBA"
Local _cPrefixo:= "PBA"

dbselectarea("SE1")

BeginSql Alias _cTabDel
	SELECT SE1.R_E_C_N_O_ AS RECSE1
	FROM %TABLE:SE1% SE1			 		 	
	WHERE E1_FILIAL=%xfilial:SE1%
        AND E1_TIPO =  %Exp:_cTipTit%
    	AND E1_PREFIXO = %Exp:_cPrefixo%
        AND E1_XIDCNT = %Exp:_cContra%
        AND E1_XIDLOC = %Exp:_cLocCtr%
		AND E1_XIDFOLH = %Exp:_cIdFolh%
		AND SE1.D_E_L_E_T_=''
EndSql

//GETLastQuery()[2]
While (_cTabDel)->(!Eof())

    SE1->(DBGOTO((_cTabDel)->RECSE1))

    RecLock("SE1",.F.)
    dbDelete()
    FaAvalSE1(2,"CJOBK06")
    FaAvalSE1(3,"CJOBK06")
    MsUnlock()

(_cTabDel)->(dbSkip())
End		
	
(_cTabDel)->(dbCloseArea())

Return
