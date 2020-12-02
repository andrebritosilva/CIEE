#Include "protheus.ch"

/*/{Protheus.doc} FA070CA2
Ponto de entrada executado após a rotina de cancelamento de baixas do contas a receber, apos a gravação de todos os dados
e finalizada a contabilização.
@author danilo.grodzicki
@since 26/06/2020
@version P 12.1.25
@type user function
/*/
User Function FA070CA2()
Local nOpcx := PARAMIXB[1]

if Round(SE1->E1_SALDO,2) == Round(SE1->E1_VALOR,2) .and. AllTrim(SE1->E1_SITUACA) == "F"  // título protestado
	RecLock("SE1", .F.)
		SE1->E1_XGERSER := " "
		SE1->E1_XDARQSE := CtoD("")
	SE1->(MsUnlock())
endif

//ALTERAÇÃO DO STATUS DE FECHAMENTO QUANDO CANCELAR A BAIXA A RECEBER

cquery := " update "+RetSqlName("ZCF")+" SET  ZCF_FECHAM='2'  "
cquery += " WHERE ZCF_PREFIX = '"+SE1->E1_PREFIXO+"'"
cquery += " AND ZCF_NUM = '" +SE1->E1_NUM+ "'"
cquery += " AND ZCF_CLIENT = '"+SE1->E1_CLIENTE+"'"
cQuery += " AND ZCF_LOJA = '"+SE1->E1_LOJA+"'"

TCSQLEXEC(cQuery)


//Gera fila DW3
IF nOpcx == 5 // Cancelamento de baixa
	U_CICOBDW3("","1")
ELSEIF nOpcx == 6 // Exclusão da baixa
    U_CICOBDW3("","1")     
ENDIF	

//Gera fila KAIROS
IF nOpcx == 5 // Cancelamento de baixa
	U_CIKAIROS("","")
ELSEIF nOpcx == 6 // Exclusão da baixa
    U_CIKAIROS("","")     
ENDIF	


Return Nil
