#Include 'Protheus.ch'

User Function FC040FIL()

Local aArea := GetArea()

AADD(aRotina, { "Relatório Inconsistência" , "U_CFINR95" , 0, 5 })

RestArea(aArea)

Return