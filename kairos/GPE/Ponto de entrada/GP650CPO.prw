#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} GP650CPO
Ponto de entrada para gravação do numero do titulo da RC1 nos registros da SRD
@author andre.brito
@since 30/07/2020
@type User function
/*/
User Function GP650CPO()

Local aArea := GetArea()

If RC1->RC1_CODTIT == '300'
	If TCSQLEXEC("UPDATE "+ RETSQLNAME("SRD") +" SET RD_XNUMTIT='"+ RC1->RC1_NUMTIT +;
				 "' WHERE RD_DATPGT BETWEEN '" + DTOS(RC1->RC1_DTBUSI) +  "' AND '" + DTOS(RC1->RC1_DTBUSF) +;
				"' AND RD_PD='509' AND D_E_L_E_T_=' '") < 0
		
		ALERT(TCSQLERROR())
		
	EndIf
EndIf

Restarea(aArea)

Return