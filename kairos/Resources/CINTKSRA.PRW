#INCLUDE "TOTVS.CH"
#INCLUDE "RESTFUL.CH"

/*/{Protheus.doc} CINTKSRA
Ajuste do código do contrato
@author danilo.grodzicki
@since 15/07/2020
@version undefined
@param
@type user function
/*/
User Function CINTKSRA()

Local _xRA_XIDCT
Local _xRA_XIDCF
Local _xRA_XIDLOCT

Local oJson := Nil

RpcSetType(3)
RpcSetEnv("01","0001")

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CINTKSRA] Inicio ajuste código do contrato")

DbSelectArea("SRA")
SRA->(DbSetOrder(01))
SRA->(DbGoTop())

while SRA->(!Eof())

	if !Empty(SRA->RA_XID) .and. !Empty(SRA->RA_XJSON)
		
		oJson := JsonObject():new()

		oJson:fromJson(SRA->RA_XJSON)

		_xRA_XIDCT   := oJson["sintetico"]:GetJsonText("idcontrato")
		_xRA_XIDLOCT := oJson["sintetico"]:GetJsonText("idlocalcontrato")
		_xRA_XIDCF   := oJson["sintetico"]:GetJsonText("idconfiguracaofaturamento")

		RecLock("SRA",.F.)
			SRA->RA_XIDCONT := _xRA_XIDCT
			SRA->RA_XIDLOCT := _xRA_XIDLOCT
			SRA->RA_XIDCONF := _xRA_XIDCF
		SRA->(MsUnlock())

	endif
	
	SRA->(DbSkip())

enddo

CONOUT("[" + LEFT(DTOC(Date()),5) + "][" + LEFT(Time(),5) + "][CINTKSRA] Fim ajuste código do contrato")

RpcClearEnv()

Return