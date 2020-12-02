#include 'parmtype.ch'
#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTK07
Serviço de integração  para integração das configurações da folha - PROCESSAMENTO DAS FILAS KAIROS
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
USER  Function CINTK07(nRecno)
	
Local oJson := nil
Local lerro := .F.
Local cErro := ""

Private cJson      := ""
Private lErroTenta := .F.

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK07] Inicio Configuração de Folha RECNO:" + CVALTOCHAR(nRecno))

//Posiciona na tabela ZCQ
DbSelectarea("ZCQ")
ZCQ->(DBGOTO(nRecno))

IF !EMPTY(ZCQ->ZCQ_JSON)	
	cJson:= ZCQ->ZCQ_JSON
	oJson:= JsonObject():new()
	oJson:fromJson(ZCQ->ZCQ_JSON)   


	//Avalia o campo operação ZCQ_OPEENV - 1=POST;2=PUT;3=DELETE  
	Do CASE

		CASE	ZCQ->ZCQ_OPEENV == '1' 	//Antigo WSMETHOD POST 

				// Valida os dados do oJson
				cErro := ValoJson(oJson,"I")
				
				if !Empty(cErro)
					cmsg:=  Alltrim(cErro)
					lErro:= .t.	
				Else
					GravaZC2(oJson)
				Endif

		CASE	ZCQ->ZCQ_OPEENV == '2'	//Antigo WSMETHOD PUT 
 
				cErro := ValoJson(oJson,"A")

				if !Empty(cErro)
					cmsg:=  Alltrim(cErro)
					lErro:= .t.	
				Else
					GravaZC2(oJson)
				Endif

		CASE	ZCQ->ZCQ_OPEENV == '3'	//Antigo WSMETHOD DELETE 

				cErro := ValoJson(oJson,"E")

				if !Empty(cErro)
					cmsg:=  Alltrim(cErro)
					lErro:= .t.	
				Else
					Begin Transaction
						RecLock("ZC2",.F.)
						ZC2->(DbDelete())
						ZC2->(MsUnLock())	

						ApagaZCB(ZCB->ZCB_IDFOLH)

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

CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CINTK07] Fim Configuração de Folha RECNO:" + CVALTOCHAR(nRecno))

RETURN


/*/{Protheus.doc} ESTUDCNT
Serviço de integração  para integração das configurações da folha
@author 	DAC - Denilso
@since 		17/10/2019
@version 	P12
@param		Não utilizado
@type class
/*/
WSRESTFUL CONFIGFOL DESCRIPTION "Serviço para integração das configurações da folha" FORMAT APPLICATION_JSON
	WSMETHOD POST; 
	DESCRIPTION "Realiza a inclusão configuração folha";
	WSSYNTAX "/CONFIGFOL"
	WSMETHOD PUT; 
	DESCRIPTION "Realiza a alteração configuração folha";
	WSSYNTAX "/CONFIGFOL"
	WSMETHOD DELETE; 
	DESCRIPTION "Realiza a exclusão configuração folha";
	WSSYNTAX "/CONFIGFOL"
	WSMETHOD GET; 
	DESCRIPTION "Realiza a consulta configuração folha";
	WSSYNTAX "/CONFIGFOL"
END WSRESTFUL 

/*/{Protheus.doc} POST
Realiza a inclusão de configuração de folha
@author DAC - Denilso
@since 17/10/2019
@version undefined
@type function
/*/
WSMETHOD POST WSSERVICE CONFIGFOL

Local cErro:= ""                                                                                                                                                                                                                             

Private cJson

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

::SetContentType('application/json')
oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))
cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"I")
If !Empty(cErro)
	U_GrvLogKa("CINTK07", "POST", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
Endif

// Realiza a gravação na tabela ZC2
GravaZC2(oJson)

U_GrvLogKa("CINTK07", "POST", "1", "Integracao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Integracao realizada com sucesso")

/*/{Protheus.doc} PUT
Realiza a atualizacao de Faturamento de nota
@author carlos.henrique
@since 01/03/2019
@version undefined
@type function
/*/
WSMETHOD PUT WSSERVICE CONFIGFOL

Local cErro:= ""                                                                                                                                                                                                                                

Private cJson

Private dDtIniInt := Date()
Private cHrIniInt := Time()
Private cHrIniDw3 := ""
Private cHrFimDw3 := ""

::SetContentType('application/json')
oJson := JsonObject():new()
oJson:fromJson(Self:GetContent(,.T.))
cJson := Self:GetContent(,.T.)

// Valida os dados do oJson
cErro := ValoJson(oJson,"A")
If !Empty(cErro)
	U_GrvLogKa("CINTK07", "PUT", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

// Realiza a gravação na tabela ZC2
GravaZC2(oJson)

U_GrvLogKa("CINTK07", "PUT", "1", "Atualização realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Atualização realizada com sucesso")

/*/{Protheus.doc} DELETE
Realiza a exclusão de Faturamento de nota
@author Danilo José Grodzicki
@since 18/10/2019
@version undefined
@type function
/*/
WSMETHOD DELETE WSSERVICE CONFIGFOL

Local cErro:= ""                                                                                                                                                                                                                                 

Private cJson

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
If !Empty(cErro)
	U_GrvLogKa("CINTK07", "DELETE", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
Endif

Begin Transaction

	RecLock("ZC2",.F.)
	ZC2->(DbDelete())
	ZC2->(MsUnLock())	

	ApagaZCB(ZCB->ZCB_IDFOLH)

End Transaction



U_GrvLogKa("CINTK07", "DELETE", "1", "Exclusao realizada com sucesso", cJson, oJson)

Return U_RESTOK(self,"Exclusao realizada com sucesso")

/*/{Protheus.doc} GET
Realiza a consulta de Faturamento de nota
@author Danilo José Grodzicki
@since 01/10/2019
@/version undefined
@type function
/*/
WSMETHOD GET WSSERVICE CONFIGFOL

Local cErro	 := ""   
Local cLocctr:= '"locaiscontratosvinculados": ['
Local cJson
Local lFound := .F.

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
If !Empty(cErro)
	U_GrvLogKa("CINTK07", "GET", "2", cErro, cJson, oJson)
	Return U_RESTERRO(Self,cErro)
endif

//Busca os locais de contrato vinculados
ZCB->(DbSetOrder(1))  //ZCB_FILIAL + ZCB_IDFOLH + ZCB_IDCNTU + ZCB_IDCNT + ZCB_IDLOC  
if ZCB->(DbSeek(xFilial("ZCB") + AvKey(ZC2->ZC2_IDFOLH,"ZCB_IDFOLH")))
	
	lFound := .T.
	
	while ZCB->(!Eof()) .and. XFilial("ZCB")+ZCB->ZCB_IDFOLH == XFILIAL("ZCB")+AvKey(ZC2->ZC2_IDFOLH,"ZCB_IDFOLH")
		
		cLocctr +='{"idcontrato": "'+EncodeUTF8(AllTrim(ZCB->ZCB_IDCNT), "cp1252") +'","idlocalcontrato": "'+EncodeUTF8(AllTrim(ZCB->ZCB_IDLOC), "cp1252")+'"},'

		ZCB->(DBSKIP())
		
	END

endif

if lFound
	cLocctr := alltrim(cLocctr)
	cLocctr := substr(cLocctr,1,len(cLocctr)-1)	
endif

cLocctr += ']'

cJson := '{	'
cJson += '	"configuracao": {'
cJson += '					"id": "' 				+ EncodeUTF8(AllTrim(ZC2->ZC2_IDFOLH)	 , "cp1252") + '",'
cJson += '					"nome": "' 				+ EncodeUTF8(AllTrim(ZC2->ZC2_DESCR), "cp1252") + '",'
cJson += '					"idcontrato": "' 		+ EncodeUTF8(AllTrim(ZC2->ZC2_IDCONT), "cp1252") + '",'
cJson += '					"bancodevolucao": {'
cJson += '										"cpf_cnpj": "' 				+ EncodeUTF8(AllTrim(ZC2->ZC2_NUMDOC), "cp1252") + '",'
cJson += '										"nome_razaosocial": "' 		+ EncodeUTF8(AllTrim(ZC2->ZC2_RAZSOC), "cp1252") + '",'
cJson += '										"banco": "' 				+ EncodeUTF8(AllTrim(ZC2->ZC2_BCODEV), "cp1252") + '",'
cJson += '										"agencia": "' 				+ EncodeUTF8(AllTrim(ZC2->ZC2_AGEDEV), "cp1252") + '",'
cJson += '										"digitoagencia": "' 		+ EncodeUTF8(AllTrim(ZC2->ZC2_AGDIGD), "cp1252") + '",'
cJson += '										"conta": "' 				+ EncodeUTF8(AllTrim(ZC2->ZC2_CONTA) , "cp1252") + '",'
cJson += '										"tipoconta": "' 			+ EncodeUTF8(AllTrim(ZC2->ZC2_CCTIPO), "cp1252") + '",'
cJson += '										"codigooperacao": "' 		+ EncodeUTF8(AllTrim(ZC2->ZC2_CODOPE), "cp1252") + '"'
cJson += '								      },'
cJson += 					cLocctr
cJson += '					}'
cJson += '}'

::SetResponse(cJson)

Return .T.

/*/{Protheus.doc} ValoJson
Valida os dados do oJson
@author DAC - Denilso
@since 17/10/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ValoJson(oJson,cTipo)

Local nI

Local cVldAux:= ""

DbSelectArea("ZC2")
ZC2->(DbSetOrder(1))

// Verifica se enviou o ID da configuração de folha
cIdConf := oJson["configuracao"]:GetJsonText("id")
if Empty(cIdConf)
	Return("O ID da configuração de folha é obrigátorio.")
endif

if cTipo == "E" .or. cTipo == "C"  // Exclusão ou Consulta

	// Verifica se o ID de configuração de folha já está cadastrado
	if !ZC2->(DbSeek(xFilial("ZC2") + Padr(AllTrim(cIdConf),TamSX3("ZC2_IDFOLH")[1]," ") ))
		Return("O ID da configuração de folha " + AllTrim(cIdConf) + " não existe.")
	endif
		
endif

// Verifica se enviou o ID do contrato e se está cadastrado
cIdCont := oJson["configuracao"]:GetJsonText("idcontrato")
if Empty(cIdCont)
	Return("O código do contrato é obrigatório.")
endif

if !ZC0->(DbSeek(xFilial("ZC0") + Padr(AllTrim(cIdCont),TamSX3("ZC0_CODIGO")[1]," ")))
	lErroTenta := .T.
	Return("O contrato: " + AllTrim(cIdCont) + " não existe.")
endif

//Valida se foi enviado array com os contratos vinculados
//if Len(oJson["configuracao"]["locaiscontratosvinculados"]) <= 0
//	Return("Array que informa os contratos vinculados esta vazio")
//endif

// Verifica se já existe o id do contrato unificado e local do contrato
if Len(oJson["configuracao"]["locaiscontratosvinculados"]) > 0
	for nI = 1 to Len(oJson["configuracao"]["locaiscontratosvinculados"])

		cIdContV := oJson["configuracao"]["locaiscontratosvinculados"][nI]:GetJsonText("idcontrato")	 
		cLocctr := oJson["configuracao"]["locaiscontratosvinculados"][nI]:GetJsonText("idlocalcontrato")	 

		//  Verificar a existencia do contrato na ZC0.
		if !ZC0->(DbSeek(xFilial("ZC0") + Padr(AllTrim(cIdContV),TamSX3("ZC0_CODIGO")[1]," ")))
			cVldAux:= "O contrato vinculado: " + AllTrim(cIdContV) + " não existe."
			EXIT
		endif

		if !ZC1->(DbSeek(xFilial("ZC1") + Padr(AllTrim(cIdContV),TamSX3("ZC1_CODIGO")[1]," ") + Padr(AllTrim(cLocctr),TamSX3("ZC1_LOCCTR")[1]," ")))
			cVldAux:= "O contrato vinculado: " + AllTrim(cIdContV) + " e o local do contrato " + AllTrim(cLocctr) + " não existem."
			EXIT
		endif	

	Next

	if !EMPTY(cVldAux)
		lErroTenta := .T.
		Return(cVldAux)
	endif

endif
		
Return ""

/*/{Protheus.doc} GravaZC2
Realiza a gravação na tabela ZC2
@author Denilso Almeida Carvalho
@since 18/10/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function GravaZC2(oJson)

Local _nPos

Local _cIdConfigura := Space(015)
Local _cIdContrato	:= Space(015)
Local _cIdContVin   := Space(015)
Local _cIdLocalCtr  := Space(015)
Local _cDescrConf   := Space(150)	
Local _cCnpjCpf	  	:= Space(014)
Local _cRazsoc   	:= Space(150)	   
Local _cBcoDev      := Space(003)	
Local _cAgDev       := Space(005)	     
Local _cAgDigDev    := Space(001)	
Local _cConta       := Space(010)
Local _cTipoConta   := Space(001)
Local _cCodOper 	:= Space(003)
Local _nQtdLocCtr	:= 0  
Local lCtrNormal	:= .T.

_cIdConfigura := AllTrim(oJson["configuracao"]:GetJsonText("id"))
_cDescrConf   := DecodeUTF8(AllTrim(oJson["configuracao"]:GetJsonText("nome")))	
_cIdContrato  := AllTrim(oJson["configuracao"]:GetJsonText("idcontrato"))
_cCnpjCpf	  := AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("cpf_cnpj"))
_cRazsoc	  := DecodeUTF8(AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("nome_razaosocial"))) 
_cBcoDev	  := AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("banco"))
_cAgDev	      := AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("agencia"))
_cAgDigDev	  := AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("digitoagencia"))
_cConta	      := AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("conta"))
_cTipoConta   := AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("tipoconta"))
_cCodOper 	  := AllTrim(oJson["configuracao"]["bancodevolucao"]:GetJsonText("codigooperacao"))

// Verifica se é contrato normal
for _nPos = 1 to Len(oJson["configuracao"]["locaiscontratosvinculados"])
	if AllTrim(_cIdContrato) <> AllTrim(oJson["configuracao"]["locaiscontratosvinculados"][_nPos]:GetJsonText("idcontrato"))
		lCtrNormal := .F.
		exit
	endif
Next

Begin Transaction

	Sleep(500)

	ZC2->(DbSetOrder(1))
	if ZC2->(DbSeek( xfilial("ZC2") + Padr(_cIdConfigura,TamSX3("ZC2_IDFOLH")[1]," ") ))
		RecLock("ZC2",.F.)
	else
		RecLock("ZC2",.T.)
	endif
		ZC2->ZC2_FILIAL := XFilial("ZC2")
		ZC2->ZC2_IDFOLH := _cIdConfigura
		ZC2->ZC2_DESCR  := _cDescrConf 
		ZC2->ZC2_IDCONT := _cIdContrato
		ZC2->ZC2_NUMDOC := _cCnpjCpf
		ZC2->ZC2_RAZSOC := _cRazsoc 
		ZC2->ZC2_BCODEV := _cBcoDev
		ZC2->ZC2_AGEDEV := _cAgDev 
		ZC2->ZC2_AGDIGD := _cAgDigDev
		ZC2->ZC2_CONTA  := _cConta
		ZC2->ZC2_CCTIPO := _cTipoConta
		ZC2->ZC2_CODOPE := _cCodOper
		ZC2->ZC2_DTINTE := Date()
		ZC2->ZC2_HRINTE := Time()
		ZC2->ZC2_JSON   := cJson
	ZC2->(MsUnlock())

	if ZC2->(DbSeek( xfilial("ZC2") + Padr(_cIdConfigura,TamSX3("ZC2_IDFOLH")[1]	  ," ") ))

		ApagaZCB(_cIdConfigura)

	endif

	//GRAVA ZCB
	_nQtdLocCtr := Len(oJson["configuracao"]["locaiscontratosvinculados"])

	If _nQtdLocCtr > 0

		For _nPos := 1 To _nQtdLocCtr

			_cIdContVin		:= AllTrim(oJson["configuracao"]["locaiscontratosvinculados"][_nPos]:GetJsonText("idcontrato"))
			_cIdLocalCtr	:= AllTrim(oJson["configuracao"]["locaiscontratosvinculados"][_nPos]:GetJsonText("idlocalcontrato"))

			RecLock("ZCB",.T.)
				ZCB->ZCB_IDFOLH := _cIdConfigura
				ZCB->ZCB_IDCNTU := _cIdContrato 
				ZCB->ZCB_IDCNT  := _cIdContVin
				ZCB->ZCB_IDLOC  := _cIdLocalCtr
				if lCtrNormal
					ZCB->ZCB_TPCONT := "1" //1-Contrato normal
				else
					ZCB->ZCB_TPCONT := IIF(Alltrim(_cIdContVin)==alltrim(_cIdContrato),"2","3") //2-Contrato Unificador, 3-Contrato Unificado
				endif
			ZCB->(MsUnLock())	

		Next _nPos

	Endif	

End Transaction

Return

/*/{Protheus.doc} ApagaZCB
Apaga registros da tabela
@author Marcelo Moraes
@since 18/10/2019
@version undefined
@param nCode, numeric, descricao
@param cMsg, characters, descricao
@type function
/*/
Static Function ApagaZCB(_cIdFOLHA)

local aArea   := GetArea()
local aAreaZCB := ZCB->(GetArea())

if !Empty(_cIdFOLHA)

	ZCB->(DbSetOrder(1))  //ZCB_FILIAL + ZCB_IDFOLH + ZCB_IDCNTU + ZCB_IDCNT + ZCB_IDLOC  
	if ZCB->(DbSeek(xFilial("ZCB") + AvKey(_cIdFOLHA,"ZCB_IDFOLH")))
		while ZCB->(!Eof()) .and. XFilial("ZCB")+ZCB->ZCB_IDFOLH == XFILIAL("ZCB")+AvKey(_cIdFOLHA,"ZCB_IDFOLH")
			
			RecLock("ZCB",.F.)
			ZCB->(DbDelete())
			ZCB->(MsUnLock())	

			ZCB->(DBSKIP())
			
		END
	endif

endif

RestArea(aAreaZCB)
RestArea(aArea)

return