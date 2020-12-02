#INCLUDE "TOTVS.CH"

/*/{Protheus.doc} MOD11
Rotina de tratamento do digito verificador do nosso numero
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/
User function MOD11(cVal)
Local cRet:= MODULO11(cVal,2,7)

IF cRet == "0"
	cRet:= "P"
ENDIF

Return cRet

/*/{Protheus.doc} NossNum
Rotina para concatenar Carteira+Nosso Numero+digito
@author carlos.henrique
@since 31/05/2019
@version undefined
@type function
/*/

User function NossNum()

Local aArea		:= GetArea()
Local aAreaSEE  := SEE->(GetArea())
Local cRet      := ""
local cDig      := ""
local cCart     := ""
local cNossoNum := ""

if !Empty(M->E1_NUMBCO)

	cNossoNum  := STRZERO(VAL(M->E1_NUMBCO),11)                             

	cDig := U_MOD11("09"+STRZERO(VAL(M->E1_NUMBCO),11)) 

	//Busca carteira
	dbSelectArea("SEE")   // Tabela de Bancos 
	dbSetOrder(1)	
	If SEE->(DbSeek(xfilial("SEE") + AvKey(M->E1_PORTADO,"EE_CODIGO") + AvKey(M->E1_AGEDEP,"EE_AGENCIA") + AvKey(M->E1_CONTA,"EE_CONTA") + AvKey(M->E1_XSUBCTA,"EE_SUBCTA"))) 
		cCart := SEE->EE_CODCART
	endif
  
	cRet := cCart + "-" + cNossoNum + "-" + cDig

endif

RestArea(aAreaSEE)
RestArea(aArea)

Return cRet
