#Include "protheus.ch"

/*/{Protheus.doc} F070ACONT
Ponto de entrada executado após a confirmação da baixa do contas a receber.
@author luis.balestrero
@since 30/07/2020
@version P 12.1.25
@type user function
/*/

  
User Function F070ACONT()

_prefger := ""
_titger  := ""


_motbx  := SuperGetMv("CI_MOTBX",,"INC") //MOTIVO DE BAIXA INCONSISTÊNCIA



IF NVALREC < SE1->E1_SALDO

_valtit := 0
_valtit := SE1->E1_VALOR - NVALREC


nRecno := SE1->(Recno())
TIT_DIF(_valtit)
SE1->(DbGoto(nRecno))



RECLOCK("SE5",.T.)
	E5_FILIAL    := xFilial("SE5")
	E5_DATA      := DDATABASE
	E5_TIPO      := SE1->E1_TIPO
	E5_NATUREZ   := SE1->E1_NATUREZ
	E5_VENCTO    := DDATABASE
	E5_NUMERO    := SE1->E1_NUM
	E5_PREFIXO   := SE1->E1_PREFIXO
	E5_VALOR     := SE1->E1_VALOR - NVALREC
	E5_RECPAG    := "R"
	E5_HISTOR    := "SLD REMAN BX PARC "
	E5_TIPODOC   := "VL"
	E5_DTDIGIT   :=  DDATABASE
	E5_MOTBX     := _motbx
	E5_DTDISPO   := DDATABASE
	E5_FILORIG   := xFilial("SE5")
	E5_CLIFOR    := SE1->E1_CLIENTE
	E5_LOJA      := SE1->E1_LOJA
	E5_CLIENTE   := SE1->E1_CLIENTE
	E5_BENEF     := SE1->E1_NOMCLI
	E5_DOCUMENT  := _prefger +  _titger
    E5_FILORIG   := cFilant
MSUNLOCK()


DBSELECTAREA("SE1")



 
ENDIF
 

reclock("SE1",.F.)
   	SE1->E1_SALDO := 0
   	SE1->E1_VALLIQ = SE1->E1_VALOR
msunlock()




RETURN(.T.)



STATIC FUNCTION TIT_DIF(_valtit)

//Local   aAreaSE1     := GetArea('SE1')


	_cNumSE1 := GETSX8NUM('SE1',"E1_NUM",,1)
	_parc    := SE1->E1_PARCELA
	_prefixo := SE1->E1_PREFIXO
	_tipo    := SE1->E1_TIPO
	_naturez := SE1->E1_NATUREZ
	_client  := SE1->E1_CLIENTE
	_loja    := SE1->E1_LOJA
	_emiss   := SE1->E1_EMISSAO
	_vencto  := SE1->E1_EMISSAO
	_vencrea := SE1->E1_VENCREA
	_valor   := _valtit
	
	aArraySE1 := { { "E1_PREFIXO"  , _Prefixo          		, NIL },;
						{ "E1_NUM"      , _cNumSE1		, NIL },;
						{ "E1_TIPO"     , _tipo              	 	, NIL },;
						{ "E1_NATUREZ"  , _Naturez 		 			, NIL },;
						{ "E1_CLIENTE"  , _client       	 			, NIL },;
						{ "E1_LOJA"     , _loja       	 			, NIL },;
						{ "E1_EMISSAO"  , _Emiss    	 			, NIL },;
						{ "E1_VENCTO"   , _Vencrea				 	, NIL },;
						{ "E1_VENCREA"  , _Vencrea					, NIL },;
						{ "E1_HIST"     , ""            			, NIL },;
						{ "E1_CNAB"     , ""     				    , NIL },;
						{ "E1_VALOR"    , _Valor      	 			, NIL } }
	
	
	
	
	lMsErroAuto := .F.	
	MsExecAuto( { |x,y| FINA040(x,y)} , aArraySE1, 3,aParamAuto)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
	
		
		If lMsErroAuto
			mostraErro()
		ELSE
		  	ConfirmSX8()
		  	alert("Gerado título:"+ SE1->E1_NUM + " No Valor de: "+ STR(SE1->E1_VALOR ))
		endif

      _prefger  := SE1->E1_PREFIXO
      _titger   := SE1->E1_NUM
	

RETURN()	

