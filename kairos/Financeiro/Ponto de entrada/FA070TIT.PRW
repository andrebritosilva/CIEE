#Include "protheus.ch"

/*/{Protheus.doc} FA070TIT
Ponto de entrada executado ap�s a confirma��o da baixa do contas a receber.
@author danilo.grodzicki
@since 25/06/2020
@version P 12.1.25
@type user function
/*/
User Function FA070TIT()

if Round(SE1->E1_SALDO,2) == Round(SE1->E1_VALOR,2) .and. AllTrim(SE1->E1_SITUACA) == "F"  // t�tulo protestado
	RecLock("SE1", .F.)
		SE1->E1_XGERSER := "S"
		SE1->E1_XDARQSE := CtoD("")
	SE1->(MsUnlock())
endif

Return(.T.)