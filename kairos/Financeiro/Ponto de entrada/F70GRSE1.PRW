#Include 'Protheus.ch'

USER FUNCTION F70GRSE1()
Local cOcorr:= PARAMIXB[1]

//Gera fila DW3
IF !EMPTY(cOcorr)
	U_CICOBDW3(SEB->EB_REFBAN,"") //Liquidado
else
    U_CICOBDW3("","2") //Baixa simples
ENDIF	

//Gera fila KAIROS
IF !EMPTY(cOcorr)
    U_CIKAIROS(SEB->EB_REFBAN,"P") // Liquidação via retorno bancário
else
    U_CIKAIROS("","P") //Baixa manual/Outros
ENDIF    

RETURN 
