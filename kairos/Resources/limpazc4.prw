#include "totvs.ch"

User Function LIMPAZC4()

Local cCodigo := space(15)

RpcSetType(3)
RpcSetEnv("01","0001")

DbSelectArea("ZC4")
ZC4->(DbSetOrder(01))
ZC4->(DbGoTop())

While ZC4->(!Eof())
	if ZC4->ZC4_IDFATU == cCodigo
		if RecLock("ZC4",.F.)
			ZC4->(DbDelete())
			ZC4->(MsUnLock())
		endif
	else
		cCodigo := ZC4->ZC4_IDFATU
	endif
	ZC4->(Dbskip())
enddo

Return