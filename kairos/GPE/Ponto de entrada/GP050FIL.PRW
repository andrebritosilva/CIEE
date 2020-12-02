#INCLUDE "PROTHEUS.CH"

 /*/{Protheus.doc} GP050FIL
Ponto de entrada para filtro de funcionários na impressão da DARF
@author carlos.henrique
@since 06/11/2019
@version undefined
@type User function
/*/
User Function GP050FIL()
Local aArea := GetArea()
Local lRet  := U_CFILTZCM()

Restarea(aArea)
Return lRet

 /*/{Protheus.doc} GP050FIL
Realiza filtro dOS estudantes vinculados a contrato de clientes na apuração do IR e impressão da DARF
@author carlos.henrique
@since 06/11/2019
@version undefined
@type User function
/*/
User Function CFILTZCM()
Local lRet:= .F.

//Verifica se o contrato está cadastrado na tabela ZCM
DBSELECTAREA("ZCM")
ZCM->(DBSETORDER(1))
IF ZCM->(DBSEEK(XFILIAL("ZCM") + SRA->RA_XIDCONT ))
    lRet:= .T.
ENDIF

return lRet
