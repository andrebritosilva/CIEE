#Include "protheus.ch"

/*/{Protheus.doc} F060ACT
Ponto de Entrada que permite a leitura das seguintes variáveis private: 
	cSituant - Situacao do título antes da transferência.
	cSituacao - Situacao do título após a transferência.
O Ponto de Entrada F060ACT será chamado após a gravação da transferência e antes da contabilização.
@author danilo.grodzicki
@since 26/06/2020
@version P 12.1.25
@type user function
/*/
User Function F060ACT()

if AllTrim(cSituant) == "F"  // título protestado
	
	RecLock("SE1", .F.)
		SE1->E1_XGERSER := "S"
		SE1->E1_XDARQSE := CtoD("")
	SE1->(MsUnlock())

else
	RecLock("SE1", .F.)
		SE1->E1_XGERSER := " "
		SE1->E1_XDARQSE := CtoD("")
	SE1->(MsUnlock())
endif

//Envio SERASA
IF PARAMIXB[1][1] == "F"
	
	//Gera fila DW3
	U_CICOBDW3("","13")

	//Gera fila KAIROS
	U_CIKAIROS("","S") 

ELSEIF PARAMIXB[1][1] == "Z" //Envio GLOBAL

	//Gera fila DW3
	U_CICOBDW3("","12")

	//Gera fila KAIROS
	U_CIKAIROS("","T") 

ENDIF


Return Nil
