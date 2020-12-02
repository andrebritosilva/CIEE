#Include 'Protheus.ch'
//---------------------------------------------------------------------------------------
/*/{Protheus.doc} F150GRV
Ponto de entrada para inclusão de segmento 2 - CNAB Modelo 1
@author  	André Brito
@since     	11/11/2020     
@return   	Nenhum 
/*/
//---------------------------------------------------------------------------------------
User Function F150GRV()

Local nHdlSaida := ParamIxb[1]     				
Local nTamEmail := 120 - Len(SA1->A1_EMAIL) 

If MV_PAR05 == "341" //Apenas se for banco Itau

    nSeq := nSeq + 2
	fWrite( nHdlSaida, "5" ) 
	fWrite( nHdlSaida, SUBSTR(SA1->A1_EMAIL,1,80))
	fWrite( nHdlSaida,  Replicate(" ",nTamEmail))
	fWrite( nHdlSaida, IIF(SA1->A1_PESSOA=="F","01","02"))
	fWrite( nHdlSaida, IF(SA1->A1_PESSOA=="F","000"+TRIM(SA1->A1_CGC),SA1->A1_CGC)) 	
	fWrite( nHdlSaida, UPPER(FWNOACCENT(SubStr(SA1->A1_END,1,40))))
	fWrite( nHdlSaida, UPPER(FWNOACCENT(Substr(SA1->A1_BAIRRO,1,12))))
	fWrite( nHdlSaida, SubStr(SA1->A1_CEP,1,8))
	fWrite( nHdlSaida, UPPER(FWNOACCENT(Substr(SA1->A1_MUN,1,15))))
	fWrite( nHdlSaida, SA1->A1_EST)
	fWrite( nHdlSaida, SPACE(180))
	fWrite( nHdlSaida, StrZero(nSeq,6) )				
	fWrite( nHdlSaida, CHR(13) + CHR(10) )
	
	nSeq := nSeq - 1
	
EndIf

Return