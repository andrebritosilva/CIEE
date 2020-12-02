#include 'protheus.ch'
#include 'parmtype.ch'

/*/{Protheus.doc} F770CPQ
Ponto de entrada para incluir parâmetros no select do FINA770A
@author Danilo José Grodzicki
@since 10/02/2020
@version 1.0
@return ${return}, ${return_description}
@type function
/*/
User Function F770CPQ()

// Incluir títulos marcados para evio para o Serasa.

Local cQuery := " E1_XSERGLO = '1' "

Return(cQuery)