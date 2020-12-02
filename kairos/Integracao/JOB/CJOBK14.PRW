#INCLUDE "TOTVS.CH"
#include "RESTFUL.CH"

/*/{Protheus.doc} CJOBK14
JOB de processamento de atualização da tabela CC2
@author danilo.grodzicki
@since 15/09/2020
@version undefined
@type user function
/*/
User function CJOBK14()

Local lJob    := GetRemoteType() == -1  // Verifica se é job
Local cEmpInt := CEMPANT
Local cFilInt := CFILANT
Local nOpca   := 0

IF !lJob
	IF MSGYESNO("Confirma o processamento de atualização da tabela CC2?")
		nOpca := 1
	ENDIF
ELSE
	CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK14] Iniciando processamento via schedule.")
	nOpca := 1
ENDIF

IF !LockByName("CJOBK14",.T.,.T.)
	nOpca := 0
	IF !lJob
		MSGINFO("Já existe um processamento em execução, aguarde!")
	ELSE
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK14] Já existe um processamento em execução, aguarde!")
	ENDIF
ENDIF

IF nOpca > 0

	IF !lJob
		FWMsgRun(,{|| CJBK14PR() },,"Realizando processamento de atualização da tabela CC2, aguarde...")
	ELSE
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK14] Processo Iniciado para " + cEmpInt + "-" + cFilInt)
		CJBK14PR()
		CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK14] Processo Finalizado para " + cEmpInt + "-" + cFilInt)
	ENDIF
	
	UnLockByName("CJOBK14",.T.,.T.)
	
ENDIF

RETURN

/*/{Protheus.doc} CJBK14PR
Método para pegar a relação dos municípios atualizados
@author danilo.grodzicki
@since 15/09/2020
@version undefined
@type function
/*/
Static function CJBK14PR()

Local nI
Local cEstado
Local cCodMun

Local oRet	  := Nil
Local oRest   := Nil
Local aHeader := {}

aAdd(aHeader, 'Content-Type: application/json' )
aAdd(aHeader, 'Accept: application/json'       )

oRest := FWRest():New("https://api.hfx.ciee.org.br")
oRest:SetPath("/core/city/search?todos=true")

If oRest:Get(aHeader)
	
	oRet := JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )

	DbSelectArea("CC2")
	CC2->(DbSetOrder(01))

	DbSelectArea("SX5")
	SX5->(DbSetOrder(01))
	
	if oRet["totalElements"] > 0
	
		for nI = 1 to Len(oRet["content"])
			
			cEstado := AllTrim(oRet["content"][nI]["state"]:GetJsonText("initials"))
			cCodMun := Right(AllTrim(oRet["content"][nI]:GetJsonText("cityCode")),5)

			if !CC2->(DbSeek(xFilial("CC2")+cEstado+cCodMun))
				
				if SX5->(DbSeek(xFilial("SX5")+"12"+cEstado))

					RecLock("CC2",.T.)
						CC2->CC2_EST    := cEstado
						CC2->CC2_CODMUN := cCodMun
						CC2->CC2_MUN    := NoAcento(DecodeUTF8(AllTrim(oRet["content"][nI]:GetJsonText("cityName"))))
						CC2->CC2_XATSIT := "S"
						CC2->CC2_XDTATU := Date()
					CC2->(MsUnlock())

				endif

//				oRet["content"][1]:GetJsonText("id")                                         // código do município
//				DecodeUTF8(AllTrim(oRet["content"][1]:GetJsonText("cityName"))))             // nome do município
//				oRet["content"][1]:GetJsonText("active")                                     // município ativo
//				oRet["content"][1]["state"]:GetJsonText("id")                                // código do estado
//				oRet["content"][1]["state"]:GetJsonText("initials")                          // UF
//				DecodeUTF8(AllTrim(oRet["content"][1]["state"]:GetJsonText("description")))  // nome do estado
//				oRet["content"][1]["state"]:GetJsonText("active")                            // estado ativo
//				oRet["content"][1]:GetJsonText("cityCode")                                   // código do município
			endif

		next
	
	endif

	FreeObj(oRet)

ELSE

	oRet := JsonObject():new()
	oRet:fromJSON( oRest:GetResult() )
	CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CJOBK14] Erro " + AllTrim(oRet:GetJsonText("status")) + "-" + AllTrim(oRet:GetJsonText("message")))
	FreeObj(oRet)

Endif

Return

/*/{Protheus.doc} Scheddef
Define parametros do processamento via schedule
@author danilo.grodzicki
@since 15/09/2020
@version undefined
@type function
/*/
Static Function Scheddef()

Local aParam := {"P","CJOBK14","",{},""}

Return aParam