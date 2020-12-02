#Include "TOTVS.ch"

/*
Função    : FI040ROT
Objetivo  : Ponto e entrada para customização das opções do mBrowse do Contas a Receber.
Parametro : aRotina
Retorno   : aRotina
Autor     : Alexsander Martins dos Santos
Data      : 05/12/2019
Empresa   : CIEE
*/
User Function FI040ROT()

Local aRotina := ParamIXB

//aAdd(aRotina, {"Alterar Data Vencimento Real", "U_C06A04DV()", 0, 8})  // User function está no fonte CFINA90.PRW
//aAdd(aRotina, {"Alterar Decréscimo"          , "U_C06A04DE()", 0, 8})  // User function está no fonte CFINA90.PRW
aAdd(aRotina, {"Tracker Kairos"              , "U_CFINA88()" , 0, 9})
aAdd(aRotina, {"Rel Analitico Repasse (ICN)" , "U_CFINR96()" , 0, 9})
aAdd(aRotina, {"Vis. Recibo"                 , "U_CFINE58()" , 0, 9})

Return(aRotina)

