#include "totvs.ch"

User Function LIMPAZC1()

Local cCodigo := space(30)

RpcSetType(3)
RpcSetEnv("01","0001")

DbSelectArea("ZC1")
ZC1->(DbSetOrder(01))
ZC1->(DbGoTop())

While ZC1->(!Eof())
	if ZC1->ZC1_CODIGO + ZC1->ZC1_LOCCTR == cCodigo
		if RecLock("ZC1",.F.)
			ZC1->(DbDelete())
			ZC1->(MsUnLock())
		endif
	else
		cCodigo := ZC1->ZC1_CODIGO + ZC1->ZC1_LOCCTR
	endif
	ZC1->(Dbskip())
enddo

Return