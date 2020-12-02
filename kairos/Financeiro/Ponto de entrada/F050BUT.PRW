#Include "TOTVS.ch"

/*
Função    : F050BUT
Objetivo  : Ponto e entrada para Adicionar botoes do usuario na EnchoiceBar do Contas a Pagar. TRACKER
Parametro : aRotina 
Retorno   : aRotina
Autor     : Luiz Enrique de Araujo
Data      : 27/05/2020
Empresa   : CIEE
*/
User Function F050BUT()

Local aOutras   := {}
Local bOutras   :={||U_CFINA89()}

AADD(aOutras,{"A Pagar", {||Eval(bOutras)},"Rastreamento", "Tracker Kairos"}) 

Return(aOutras)