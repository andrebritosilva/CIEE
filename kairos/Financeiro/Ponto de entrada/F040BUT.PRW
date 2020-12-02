#Include "TOTVS.ch"

/*
Função    : F040BUT
Objetivo  : Ponto e entrada para Adicionar botoes do usuario na EnchoiceBar do Contas a Receber. TRACKER
Parametro : aRotina
Retorno   : aRotina
Autor     : Luiz Enrique de Araujo
Data      : 21/05/2020
Empresa   : CIEE
*/
User Function F040BUT()

Local aOutras   := {}
Local bOutras   :={||U_CFINA88()}

AADD(aOutras,{"A Receber", {||Eval(bOutras)},"Rastreamento", "Tracker Kairos"}) 

Return(aOutras)