#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE 'FWADAPTEREAI.CH'

user function CEAIJSON()

	RpcSetType(3)
	IF RPCSetEnv("99","01")  
		intFatCI()
	ENDIF

	//TESTE GIT Luiz
	
	RpcClearEnv()

Return

Static function intFatCI()	
//Local cJson  := ''
Local aCNPJ  := {}
Local aTipos := getTipos(@aCNPJ)
Local oRest  := FWRest():New("http://cdprxc.hom.protheus.totvscloud.com.br:33884/rest")
Local aHeader:= {}
Local nCnta,nCntx
Local aDad := {}
Private aAux := {}

Aadd(aHeader,'Content-Type: application/json')
Aadd(aHeader,'Tenantid: 01,0001')
Aadd(aHeader,'Authorization: BASIC U2lnYToxMDA2MTE=')

oRest:setPath("/FATURA")

For nCntx:= 1 to LEN(aTipos)
	
	cDescr:= aTipos[nCntx][1]
	
	aDad:= ACLONE(aTipos[nCntx][2])
	
	For nCnta:= 1 to LEN(aDad)
	
		aAux:= ACLONE(aDad[nCnta])
	
		//intCont(aDad[nCnta][7],aDad[nCnta][23],cDescr,aCNPJ[nCntx])
		//intCFat(aDad[nCnta][8],cDescr,aDad[nCnta][7])
		//intCCob(aDad[nCnta][9],cDescr,aDad[nCnta][7],aDad[nCnta][8],aDad[nCnta][23])
		
		
		U_CINTEAI()
		
		/*
		cJson:= ' {'
		cJson+= '    "sintetico":{'
		cJson+= '       "idfatura":"'+aDad[nCnta][1]+'",'
		cJson+= '       "idfolha":"'+aDad[nCnta][2]+'",'
		cJson+= '       "lote":"'+aDad[nCnta][3]+'",'
		cJson+= '       "seqlote":"'+aDad[nCnta][4]+'",'
		cJson+= '       "processo":"'+aDad[nCnta][5]+'",'
		cJson+= '       "loterastreamento":"'+aDad[nCnta][6]+'",'
		cJson+= '       "idcontrato":"'+aDad[nCnta][7]+'",'
		cJson+= '       "idconfiguracaofaturamento":"'+aDad[nCnta][8]+'",'
		cJson+= '       "idconfiguracaocobranca":"'+aDad[nCnta][9]+'",'
		cJson+= '       "quantidade_tce_tca":"'+aDad[nCnta][10]+'",'
		cJson+= '       "tipoproduto":"'+aDad[nCnta][11]+'",'
		cJson+= '       "valortotal":'+aDad[nCnta][12]+','
		cJson+= '       "datavencimento":"'+aDad[nCnta][13]+'",'
		cJson+= '       "bancofaturamento":"'+aDad[nCnta][14]+'",'
		cJson+= '       "mensagemnota":"'+aDad[nCnta][15]+'",'
		cJson+= '       "analitico":['
		cJson+= '          {'
		cJson+= '             "id":"'+aDad[nCnta][17]+'",'
		cJson+= '             "cpf":"'+aDad[nCnta][18]+'",'
		cJson+= '             "nome":"'+aDad[nCnta][19]+'",'
		cJson+= '             "nomesocial":"'+aDad[nCnta][20]+'",'
		cJson+= '             "competencia":"'+aDad[nCnta][21]+'",'
		cJson+= '             "codigo_tce_tca":"'+aDad[nCnta][22]+'",'
		cJson+= '             "unidadeciee_localcontrato":"'+aDad[nCnta][23]+'",'
		cJson+= '             "tipo_faturamento":"'+aDad[nCnta][24]+'",'
		cJson+= '             "valor":'+aDad[nCnta][25]
		cJson+= '          }'
		cJson+= '       ]'
		cJson+= '    }'
		cJson+= ' }'
	
		oRest:SetPostParams(EncodeUTF8(cJson,"cp1252"))
		
		if oRest:Post(aHeader)
			CONOUT(oRest:GetResult())
		ELSEIF Empty(oRest:CINTERNALERROR)
			oJson := JsonObject():new()
			oJson:fromJson(FwNoAccent(DecodeUTF8(oRest:GetResult())))
			CONOUT("Erro: "+oJson:GetJsonText("errorCode"))
			CONOUT("Mensagem: "+oJson:GetJsonText("errorMessage"))	
			MemoWrite("C:\Temp\Cenario\FAT_"+TRIM(aDad[nCnta][1]),cJson)
		ELSE
			CONOUT(oRest:CINTERNALERROR)
		endif	
		*/
	NEXT
NEXT
	
RETURN

Static function getTipos(aCNPJ)
Local aTipos:= {}
Local aRet:= {}

//1� emiss�o
AADD(aCNPJ,"01638821000110")
AADD(aRet,{'1','','AI20191110010010','1','1','','51','27','35','3','1','339','30/11/2019','237','','','24738916','12932768875','Fulano da Silva','Fulana','11/2019','3214569870','101','1','113'})
AADD(aRet,{'1','','AI20191110010010','2','1','','51','27','35','3','1','339','30/11/2019','237','','','31248470','23181810037','Ciclano de Tal','Ciclana','11/2019','7541510770','101','1','113'})
AADD(aRet,{'1','','AF20191110010010','3','1','','51','27','35','3','1','339','30/11/2019','237','','','21585446','25457184023','Beltrano de Tal','Beltrana','11/2019','5450565100','101','1','113'})

AADD(aTipos,{"Cen�rio - 1a emiss�o",aRet})
aRet:= {}


//2� emiss�o
AADD(aCNPJ,"53369903000100")
AADD(aRet,{'17','','AI20191101010500','1','2','','67','45','61','2','1','242','20/11/2019','341','','','54504783','48064584511','Jo�o da Silva','Joana','10/2019','5455066545','2401','1','121'})
AADD(aRet,{'17','','AI20191101010500','2','2','','67','45','61','2','1','242','20/11/2019','341','','','44540502','54507444801','Jos� Pereira','Josefa','10/2019','8810640662','2401','1','121'})
AADD(aRet,{'18','','AF20191101010500','3','2','','82','53','37','1','1','113','20/11/2019','237','','','24045510','45385464581','Neusa Maria','Nestor','10/2019','2145003554','2401','1','113'})

AADD(aTipos,{"Cen�rio - 2a emiss�o",aRet})
aRet:= {}

//Rastremaento de 1� e 2�
AADD(aCNPJ,"78518933000162")
AADD(aRet,{'25','','AI20191101021501','1','3','AI2019110102150157','82','53','37','1','1','113','20/11/2019','237','','','24045510','45385464581','Neusa Maria','Nestor','05/2019','2145003554','2401','1','113'})
AADD(aRet,{'26','','AI20191101021501','2','3','AI2019110102150157','82','53','37','1','1','113','20/11/2019','237','','','24045510','45385464581','Neusa Maria','Nestor','06/2019','2145003554','2401','1','113'})
AADD(aRet,{'27','','AI20191101021501','3','3','AI2019110102150157','82','53','37','1','1','113','20/11/2019','237','','','24045510','45385464581','Neusa Maria','Nestor','07/2019','2145003554','2401','1','113'})
AADD(aRet,{'28','','AI20191101021501','4','3','AI2019110102150157','82','53','37','1','1','113','20/11/2019','237','','','24045510','45385464581','Neusa Maria','Nestor','08/2019','2145003554','2401','1','113'})
AADD(aRet,{'29','','AF20191101021501','5','3','AI2019110102150157','82','53','37','1','1','113','20/11/2019','237','','','24045510','45385464581','Neusa Maria','Nestor','09/2019','2145003554','2401','1','113'})

AADD(aTipos,{"Cen�rio - Rastreamento de 1a e 2a",aRet})
aRet:= {}

//Diferenciada
AADD(aCNPJ,"91507042000179")
AADD(aRet,{'42','','AI20191102010017','1','4','','12','58','67','2','1','234','26/11/2019','341','','','24045455','55145100237','Marcos Junior','Marcia','11/2019','5455065504','201','1','117'})
AADD(aRet,{'42','','AF20191102010017','2','4','','12','58','67','2','1','234','26/11/2019','341','','','24584040','57454840155','Andre Andrade','Andreia','11/2019','4544847875','201','1','117'})

AADD(aTipos,{"Cen�rio - Diferenciada",aRet})
aRet:= {}

//Rastremento de Diferenciada
AADD(aCNPJ,"13630185000160")
AADD(aRet,{'53','','AI20191108010702','1','5','AI2019110801070263','47','59','75','1','1','145','27/11/2019','237','','','54545402','57888408888','Rafaela Oliveira','Rafael','11/2019','5457777888','131','1','145'})
AADD(aRet,{'54','','AF20191108010702','2','5','AI2019110801070277','25','42','77','1','1','123','27/11/2019','237','','','45405101','54540545400','Manoela Correia','Manuel','11/2019','5450444544','171','1','123'})

AADD(aTipos,{"Cen�rio - Rastremento de Diferenciada",aRet})
aRet:= {}

//Validar Pr�via de Faturamento
AADD(aCNPJ,"38934698000195")
AADD(aRet,{'68','','MI20191103093751','1','6','','39','47','53','3','1','369','23/11/2019','341','Faturamento 11/2019 - 39','','54054001','88450550611','Mario Lago','Maria','11/2019','4154547054','142','1','123'})
AADD(aRet,{'68','','MI20191103093751','2','6','','39','47','53','3','1','369','23/11/2019','341','Faturamento 11/2019 - 39','','48747478','48454000454','Milton Souza','Milene','11/2019','1545404412','142','1','123'})
AADD(aRet,{'68','','MF20191103093751','3','6','','39','47','53','3','1','369','23/11/2019','341','Faturamento 11/2019 - 39','','88458780','85748540545','Suzy Rios','S�rgio','11/2019','8884804551','142','1','123'})

AADD(aTipos,{"Cen�rio - Validar Pr�via de Faturamento",aRet})
aRet:= {}

//Folha
AADD(aCNPJ,"55043429000158")
AADD(aRet,{'77','65','MI20191105111702','1','7','','48','55','46','5','1','260','05/11/2019','237','','','54454044','52121241000','Ary Travassos','Ariane','11/2019','8584002112','111','1','52'})
AADD(aRet,{'77','65','MI20191105111702','2','7','','48','55','46','5','1','260','05/11/2019','237','','','57540454','54554545402','Bela Santos','Beto','11/2019','2154545054','111','1','52'})
AADD(aRet,{'77','65','MI20191105111702','3','7','','48','55','46','5','1','260','05/11/2019','237','','','55445454','88878750545','Carla Prieto','Cassia','11/2019','3565565622','111','1','52'})
AADD(aRet,{'77','65','MI20191105111702','4','7','','48','55','46','5','1','260','05/11/2019','237','','','99989445','54854544747','Diana Barros','Dario','11/2019','8845421211','111','1','52'})
AADD(aRet,{'77','65','MF20191105111702','5','7','','48','55','46','5','1','260','05/11/2019','237','','','98654545','88848848480','Esther Castro','Eduardo','11/2019','8555666441','111','1','52'})

AADD(aTipos,{"Cen�rio - Folha",aRet})
aRet:= {}

return aTipos	

/*Static function intCont(cContr,cLocal,cDescr,cCNPJ)	
Local cJson  := ''
Local oRest  := FWRest():New("http://cdprxc.hom.protheus.totvscloud.com.br:33884/rest")
Local aHeader:= {}

Aadd(aHeader,'Content-Type: application/json')
Aadd(aHeader,'Tenantid: 01,0001')
Aadd(aHeader,'Authorization: BASIC U2lnYToxMDA2MTE=')

oRest:setPath("/CONTRATO")
	
cJson+= '{'
cJson+= '  "EMPRESA": {'
cJson+= '    "idContrato": "'+cContr+'",'
cJson+= '    "tipoContrato": "1",'
cJson+= '    "tipoAprendiz": null,'
cJson+= '    "programaAprendizagem": "Aprendiz Legal",'
cJson+= '    "tipoEmpresa": "",'
cJson+= '    "razaoSocial": "'+cDescr+'",'
cJson+= '    "nomeFantasia": "'+cDescr+'",'
cJson+= '    "documento": "'+cCNPJ+'",'
cJson+= '    "sitcontrato": "1",'
cJson+= '    "sitempresa": "ATIVO",'
cJson+= '    "formaPagamento": "2",'
cJson+= '    "ENDERECO": {'
cJson+= '      "cep": "77817600",'
cJson+= '      "logradouro": "Rua",'
cJson+= '      "endereco": "W-006",'
cJson+= '      "numero": "200",'
cJson+= '      "complemento": "",'
cJson+= '      "bairro": "Jardim It�lia",'
cJson+= '      "codigoMunicipioIBGE": "02109",'
cJson+= '      "cidade": "ARAGUAINA",'
cJson+= '      "uf": "TO"'
cJson+= '    },'
cJson+= '    "LOCALCONTRATO": {'
cJson+= '      "id": '+cLocal+','
cJson+= '      "razaoSocial": "'+cDescr+'",'
cJson+= '      "nomeFantasia": "'+cDescr+'",'
cJson+= '      "documento": "'+cCNPJ+'",'
cJson+= '      "inscricaoEstadual": "",'
cJson+= '      "inscricaoMunicipal": "",'
cJson+= '      "ENDERECO": {'
cJson+= '        "cep": "77817630",'
cJson+= '        "logradouro": "Rua",'
cJson+= '        "endereco": "Amper",'
cJson+= '        "numero": "1250",'
cJson+= '        "complemento": "",'
cJson+= '        "bairro": "Loteamento Pampulha",'
cJson+= '        "codigoMunicipioIBGE": "02109",'
cJson+= '        "cidade": "ARAGUAINA",'
cJson+= '        "uf": "TO"'
cJson+= '      },'
cJson+= '      "CONSULTOR": {'
cJson+= '        "id": "",'
cJson+= '        "nome": "",'
cJson+= '        "idCarteira": "",'
cJson+= '        "dsCarteira": ""'
cJson+= '      }'
cJson+= '    },'
cJson+= '    "CONSULTOR": {'
cJson+= '      "id": "",'
cJson+= '      "nome": "",'
cJson+= '      "idCarteira": "",'
cJson+= '      "dsCarteira": ""'
cJson+= '    }'
cJson+= '  }'
cJson+= '}'

oRest:SetPostParams(EncodeUTF8(cJson, "cp1252"))

if oRest:Post(aHeader)
	CONOUT(oRest:GetResult())
ELSEIF Empty(oRest:CINTERNALERROR)
	oJson := JsonObject():new()
	oJson:fromJson(FwNoAccent(DecodeUTF8(oRest:GetResult())))
	CONOUT("Erro: "+oJson:GetJsonText("errorCode"))
	CONOUT("Mensagem: "+oJson:GetJsonText("errorMessage"))	
	MemoWrite("C:\Temp\Cenario\CONT_"+TRIM(cContr),cJson)	
ELSE
	CONOUT(oRest:CINTERNALERROR)	
endif
	
RETURN*/

/*Static function intCFat(cIdCfg,cDescr,cContr)	
Local cJson  := ''
Local oRest  := FWRest():New("http://cdprxc.hom.protheus.totvscloud.com.br:33884/rest")
Local aHeader:= {}

Aadd(aHeader,'Content-Type: application/json')
Aadd(aHeader,'Tenantid: 01,0001')
Aadd(aHeader,'Authorization: BASIC U2lnYToxMDA2MTE=')

oRest:setPath("/CONFIGFAT")
	
cJson+= '{'
cJson+= '   "CONFIGURACAO":{' 
cJson+= '      "id":"'+cIdCfg+'",'
cJson+= '      "nome":"'+cDescr+'",'
cJson+= '      "sitConfiguracao":"1",'
cJson+= '      "idContrato":"'+cContr+'",'
cJson+= '      "ContratoUnico":"S",'
cJson+= '      "REPRESENTANTE":{'
cJson+= '         "nome":"Fulando de tal",'
cJson+= '         "documento":"53124505026",'
cJson+= '         "areaSetor":"�rea/Setor",'
cJson+= '         "cargo":"Cargo",'
cJson+= '         "email":"teste@teste.com.br",'
cJson+= '         "ddd":"47",'
cJson+= '         "telefone":"999575786",'
cJson+= '         "ramal":""'
cJson+= '      },'
cJson+= '      "CONTRIBUICAO":{'
cJson+= '         "tipo":"1",'
cJson+= '         "percentual":"134",'
cJson+= '         "valorCIEstudante":"0.00",'
cJson+= '         "FAIXAS":[],'
cJson+= '         "valorContribuicao":"134.00",'
cJson+= '         "mesbase":"9",'
cJson+= '         "Indice":"3",'
cJson+= '         "ContribuicaoInicial":"0.00",'
cJson+= '         "EMISSAO":{'
cJson+= '            "tipo":"1",'
cJson+= '            "dia":"25"'
cJson+= '         },'
cJson+= '         "validaFaturamento":"",'
cJson+= '         "permutaFaturamento":"S",'
cJson+= '         "bancoFaturamento":"33",'
cJson+= '         "reajusteanual":"S",'
cJson+= '         "repasseEmpresa":"N"'
cJson+= '      }'
cJson+= '   }'
cJson+= '}'

oRest:SetPostParams(EncodeUTF8(cJson, "cp1252"))

if oRest:Post(aHeader)
	CONOUT(oRest:GetResult())
ELSEIF Empty(oRest:CINTERNALERROR)
	oJson := JsonObject():new()
	oJson:fromJson(FwNoAccent(DecodeUTF8(oRest:GetResult())))
	CONOUT("Erro: "+oJson:GetJsonText("errorCode"))
	CONOUT("Mensagem: "+oJson:GetJsonText("errorMessage"))	
	MemoWrite("C:\Temp\Cenario\CFGF_"+TRIM(cIdCfg),cJson)
ELSE
	CONOUT(oRest:CINTERNALERROR)	
endif		
	
RETURN*/

/*Static function intCCob(cIdCfg,cDescr,cContr,cIdFat,cLocal)	
Local cJson  := ''
Local oRest  := FWRest():New("http://cdprxc.hom.protheus.totvscloud.com.br:33884/rest")
Local aHeader:= {}

Aadd(aHeader,'Content-Type: application/json')
Aadd(aHeader,'Tenantid: 01,0001')
Aadd(aHeader,'Authorization: BASIC U2lnYToxMDA2MTE=')

oRest:setPath("/CONFIGCOB")
	
cJson+= '{'
cJson+= '   "CONFIGURACAO":{'
cJson+= '      "id":'+cIdCfg+','
cJson+= '      "nome":"'+cDescr+'",'
cJson+= '      "padrao":"1",'
cJson+= '      "idContrato":'+cContr+','
cJson+= '      "validaFaturamento":"2",'
cJson+= '      "idConfiguracaofaturamento":'+cIdFat+','
cJson+= '      "DADOSCONTATOCOBRANCA":{'
cJson+= '         "nome":null,'
cJson+= '         "documento":null,'
cJson+= '         "ddd":null,'
cJson+= '         "telefone":null,'
cJson+= '         "ramal":null,'
cJson+= '         "email":null,'
cJson+= '         "cargo":null'
cJson+= '      },'
cJson+= '      "FICHACOBRANCABANCARIA":{'
cJson+= '         "enviaBanco":"0",'
cJson+= '         "enviaBoletoEmail":"0",'
cJson+= '         "email":null,'
cJson+= '         "CREDITOEMCONTA":{'
cJson+= '            "banco":null,'
cJson+= '            "agencia":null,'
cJson+= '            "conta":null'
cJson+= '         },'
cJson+= '         "DATADEVENCIMENTO":{'
cJson+= '            "tipo":1,'
cJson+= '            "TPPADRAO":{'
cJson+= '               "data":null'
cJson+= '            },'
cJson+= '            "TPDIAVENCIMENTO":{'
cJson+= '               "diaVencimento":null,'
cJson+= '               "competencia":null,'
cJson+= '               "diaSemana":null,'
cJson+= '               "regraFeriado":null'
cJson+= '            },'
cJson+= '            "TPDIASUTEISCORRIDOS":{ '
cJson+= '               "regra":null,'
cJson+= '               "qtdDias":null,'
cJson+= '               "dia":null,'
cJson+= '               "regraFeriadoConsiderar":null'
cJson+= '            }'
cJson+= '         },'
cJson+= '         "ENDERECO":{ '
cJson+= '            "cep":2222000,'
cJson+= '            "logradouro":"Rua",'
cJson+= '            "endereco":"Bas�lio Alves Morango",'
cJson+= '            "numero":110,'
cJson+= '            "complemento":null,'
cJson+= '            "bairro":"Jardim Brasil (Zona Norte)",'
cJson+= '            "codigoIBGE":"50308",'
cJson+= '            "cidade":"S�o Paulo",'
cJson+= '            "uf":"SP",'
cJson+= '            "mensagem":"Aos Cuidados Config 003"'
cJson+= '         }'
cJson+= '      },'
cJson+= '      "OUTRASCONFIGURACOES":{ '
cJson+= '         "RECIBO":{ '
cJson+= '            "emite":"2",'
cJson+= '            "banco":null,'
cJson+= '            "agencia":null,'
cJson+= '            "conta":null,'
cJson+= '            "observacao":null,'
cJson+= '            "ValorTotal":null,'
cJson+= '            "ReciboAutomatico":null'
cJson+= '         },'
cJson+= '         "CARTAFATURA":{ '
cJson+= '            "emite":"2",'
cJson+= '            "observacao":null,'
cJson+= '            "unificaLocal":null'
cJson+= '         },'
cJson+= '         "NOTAFISCAL":{ '
cJson+= '            "emite":"2",'
cJson+= '            "observacao":null,'
cJson+= '            "email":null,'
cJson+= '            "valorTotal":null'
cJson+= '         },'
cJson+= '         "COBRANCASERASA":{' 
cJson+= '            "envia":"2",'
cJson+= '            "qtdDias":null'
cJson+= '         },'
cJson+= '         "COBRANCATERCEIRO":{' 
cJson+= '            "envia":"2",'
cJson+= '            "qtdDias":null'
cJson+= '         },'
cJson+= '         "RepasseEmpresa":"2",'
cJson+= '         "CISeparada":"2"'
cJson+= '      },'
cJson+= '      "LOCAISCONTRATOSVINCULADOS":{' 
cJson+= '         "idLocalContratoResponsavel":'+cLocal+','
cJson+= '         "idUnidade":22,'
cJson+= '         "documento":"56805606944009",'
cJson+= '         "LOCAISCONTRATOS":[' 
cJson+= '            {' 
cJson+= '               "IdLocalContrato":'+cLocal
cJson+= '            }'
cJson+= '         ]'
cJson+= '      }'
cJson+= '   }'
cJson+= '}'

oRest:SetPostParams(EncodeUTF8(cJson, "cp1252"))

if oRest:Post(aHeader)
	CONOUT(oRest:GetResult())
ELSEIF Empty(oRest:CINTERNALERROR)
	oJson := JsonObject():new()
	oJson:fromJson(FwNoAccent(DecodeUTF8(oRest:GetResult())))
	CONOUT("Erro: "+oJson:GetJsonText("errorCode"))
	CONOUT("Mensagem: "+oJson:GetJsonText("errorMessage"))	
	MemoWrite("C:\Temp\Cenario\CFGF_"+TRIM(cIdCfg),cJson)	
ELSE
	CONOUT(oRest:CINTERNALERROR)	
endif		
	
RETURN*/
/*/{Protheus.doc} CINTEAI
Rotina de integra��o EAI JSON
@author carlos.henrique
@since 01/02/2019
@version undefined
@type function
/*/
User Function CINTEAI()
Local aRet	:= FwIntegdef("CEAIJSON")
Local lRet	:= .T.

If ValType(aRet) == "A"
	If aRet[1]
		lRet := .T.
	Else
		lRet := .F.
		If !Empty(aRet[2])	
			Help(" ",1,"FWINTEGDEF",, aRet[2] ,3,0)
		Else
			Aviso("Aten��o","Verificar problema no Monitor EAI",{"OK"},3)
		Endif
	Endif
Endif

Return lRet
/*/{Protheus.doc} IntegDef
Rotina de defini��o da integra��o
@author carlos.henrique
@since 01/02/2019
@version undefined
@param oJson, characters, descricao
@param cTypeTran, characters, descricao
@param cTypeMsg, characters, descricao
@param cVersion, characters, descricao
@type function
/*/
/*Static Function IntegDef(cJson, cTypeTran, cTypeMsg, cVersion)
Local lRet	:= .T.

Do Case
	Case (cTypeTran==TRANS_SEND)
		
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CEAIJSON] ENVIANDO MENSAGEM.")
        
		cJson:= ' {'
		cJson+= '    "sintetico":{'
		cJson+= '       "idfatura":"'+aAux[1]+'",'
		cJson+= '       "idfolha":"'+aAux[2]+'",'
		cJson+= '       "lote":"'+aAux[3]+'",'
		cJson+= '       "seqlote":"'+aAux[4]+'",'
		cJson+= '       "processo":"'+aAux[5]+'",'
		cJson+= '       "loterastreamento":"'+aAux[6]+'",'
		cJson+= '       "idcontrato":"'+aAux[7]+'",'
		cJson+= '       "idconfiguracaofaturamento":"'+aAux[8]+'",'
		cJson+= '       "idconfiguracaocobranca":"'+aAux[9]+'",'
		cJson+= '       "quantidade_tce_tca":"'+aAux[10]+'",'
		cJson+= '       "tipoproduto":"'+aAux[11]+'",'
		cJson+= '       "valortotal":'+aAux[12]+','
		cJson+= '       "datavencimento":"'+aAux[13]+'",'
		cJson+= '       "bancofaturamento":"'+aAux[14]+'",'
		cJson+= '       "mensagemnota":"'+aAux[15]+'",'
		cJson+= '       "analitico":['
		cJson+= '          {'
		cJson+= '             "id":"'+aAux[17]+'",'
		cJson+= '             "cpf":"'+aAux[18]+'",'
		cJson+= '             "nome":"'+aAux[19]+'",'
		cJson+= '             "nomesocial":"'+aAux[20]+'",'
		cJson+= '             "competencia":"'+aAux[21]+'",'
		cJson+= '             "codigo_tce_tca":"'+aAux[22]+'",'
		cJson+= '             "unidadeciee_localcontrato":"'+aAux[23]+'",'
		cJson+= '             "tipo_faturamento":"'+aAux[24]+'",'
		cJson+= '             "valor":'+aAux[25]
		cJson+= '          }'
		cJson+= '       ]'
		cJson+= '    }'
		cJson+= ' }'    
        
	Case (cTypeTran==TRANS_RECEIVE)
		
		CONOUT("["+LEFT(DTOC(Date()),5)+"]["+LEFT(Time(),5)+"][CEAIJSON] RECEBENDO MENSAGEM.")
		
		//CONOUT("JSON: "+cJson)
		cJson:= "TESTE"
			
EndCase

DelClassIntF()
	
Return {lRet,cJson}*/