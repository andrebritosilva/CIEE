#include "totvs.ch"

User Function ACEZC5()

RpcSetType(3)
RpcSetEnv("01","0001")

DbSelectArea("SE1")
SE1->(DbSetOrder(02))

DbSelectArea("ZC5")
ZC5->(DbSetOrder(01))
ZC5->(DbGoTop())

While ZC5->(!Eof())
	if SE1->(DbSeek(xFilial("SE1")+ZC5->ZC5_CLIENT+ZC5->ZC5_LOJA+ZC5->ZC5_SERIE+ZC5->ZC5_NOTA))
		RecLock("ZC5",.F.)
			ZC5->ZC5_IDFATU := SE1->E1_XIDFATU
		ZC5->(MsUnLock())
	endif
	ZC5->(Dbskip())
enddo

Return