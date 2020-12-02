#include "totvs.ch"

User Function LIMPARCH()
Local cTRCH:= GetNextAlias()

BeginSql Alias cTRCH
    SELECT R_E_C_N_O_ AS RECRCH FROM %TABLE:RCH% RCH 
    WHERE RCH_FILIAL=%xfilial:RCH%
	AND RCH_STATUS='0'
    AND RCH.D_E_L_E_T_ =''
    ORDER BY RCH_PROCES,RCH_NUMPAG DESC	
EndSql

WHILE (cTRCH)->(!EOF())	

    RCH->(DBGOTO((cTRCH)->RECRCH))
    IF RCH->(!EOF())
		HEXCPER(RCH->RCH_ROTEIR,RCH->RCH_PROCES,RCH->RCH_DTINI ,RCH->RCH_NUMPAG)
    ENDIF

(cTRCH)->(dbSkip())
end

(cTRCH)->(dbCloseArea())

msginfo("Concluido!!")

Return

/*/{Protheus.doc} HEXCPER
Exclui novo perído 
@author carlos.henrique
@since 30/01/2019
@version undefined
@type function
/*/
Static function HEXCPER(_cRoteiro,_cProcesso,_dDataRef,_cNumPag)
Local cPerCal:= ANOMES(_dDataRef)
Local cKey:= ""

RGA->(dbSetOrder(1))
IF RGA->(dbSeek(xFilial("RGA") + _cProcesso + _cRoteiro ))
	RG6->(dbSetOrder(1))
	If RG6->(dbSeek(xFilial("RG6") + RGA->RGA_PDPERI + STRZERO(MONTH(_dDataRef),2) + _cNumPag ))
		RG6->(RecLock("RG6",.F.))
		RG6->(DBDELETE())
		RG6->(MsUnLock()) 
	endif
endif

cKey :=  xFilial("RCH") + _cProcesso + cPerCal + _cNumPag + _cRoteiro

RCH->(dbSetOrder(1))	
IF RCH->(dbSeek(cKey))

	RecLock("RCH",.F.)
	RCH->(DBDELETE())
	RCH->(MsUnLock()) 

	cKey :=  xFilial("RCH") + _cProcesso + cPerCal + _cNumPag 
	RCF->(dbSetOrder(3))
	IF RCF->(dbSeek(cKey))
		RCF->(RecLock("RCF",.F.))
		RCF->(DBDELETE())
		RCF->(MsUnLock())
	ENDIF

	cKey :=  xFilial("RFQ") + _cProcesso + cPerCal + _cNumPag 
	RFQ->(dbSetOrder(1))
	IF RFQ->(dbSeek(cKey))
		RecLock("RFQ",.F.)
		RFQ->(DBDELETE())
		RFQ->(MsUnLock())
	ENDIF

ENDIF
	

Return
