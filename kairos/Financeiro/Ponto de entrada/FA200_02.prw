#include 'protheus.ch'

/*/{Protheus.doc} F200AVL
Ponto de entrada no retorno das cobran�as na ocorr�ncia de confirma��o
@author carlos.henrique
@since 12/12/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
User function FA200_02()
Local aArea1:= GetArea()
Local aArea2:= SE1->(GetArea())

//Gera fila de cobran�a DW3
U_CICOBDW3(SEB->EB_OCORR,"")


RestArea(aArea1)
RestArea(aArea2)
Return


