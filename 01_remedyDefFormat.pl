##########################################################################
#
# プログラム名：03_remedyDefFormat.pl
# 処理概要：RemedyでExportしたdefファイルから定義情報を出力する
# 引数：①入力フォルダ
# 　　：②出力ファイルプレフィックス(任意)
#
# 例：perl 03_remedyDefFormat.pl C:\Users\0018559323\Desktop\SVN\CURE-e\Remedy test_
#     
#     ■以下が出力される
#		・test_03_remedyDefFormat_0_form.dat			フォームの情報
#		・test_03_remedyDefFormat_1_activeLink.dat		アクティブリンクの情報
#		・test_03_remedyDefFormat_1_charMenu.dat		メニューの情報
#		・test_03_remedyDefFormat_1_container.dat		コンテナ(アクティブリンクガイド、フィルタガイド)の情報
#		・test_03_remedyDefFormat_1_escalation.dat		エスカレーションの情報
#		・test_03_remedyDefFormat_1_filter.dat			フィルタの情報
#		・test_03_remedyDefFormat_2_al_action.dat		アクティブリンクのアクション情報
#		・test_03_remedyDefFormat_2_ct_reference.dat	コンテナの参照情報
#		・test_03_remedyDefFormat_2_fl_action.dat		フィルタのアクション情報
#		・test_03_remedyDefFormat_3_table_Field.dat		テーブルフィールドの一覧情報
#		・test_03_remedyDefFormat_work.dat				ログ出力
#
# 改定履歴
#-------------------------------------------------------------------------
# 2015/10/27	Okuno	テーブルフィールドの列で参照先がSelection Dataの場合、その値を設定する
# 2015/10/28	Okuno	enum-value-num処理を変更 + 2 ⇒ + 1
# 2015/11/04	Okuno	open-window の項目を変更
# 2015/11/24	Okuno	EscalationのActionを取得、出力するように変更
# 2015/12/17	Okuno	谷藤さん指摘部分を反映
# 2016/01/28	Okuno	配列の持ち方を変更
# 2016/01/29	Okuno	Action関数を共通化
# 2016/02/02	Okuno	出力フォーマットの変更(エクセルマクロを不要にする)
# 2016/03/29	Okuno	すでに処理済みのオブジェクトは処理しない(先勝ち)対応
# 2016/03/30	Okuno	ファイルの処理順を確認するためファイル名を出力
#				Okuno	カラムフィールドのSelection Dataの置換対応
# 2016/03/31	Okuno	Action系の出力を統合
# 2016/04/06	Okuno	指定バイト数の文字列取得処理を統合
# 2016/04/19	Okuno	デフォルト値の置換(replaceDefault)の改修
# 2016/11/08	Okuno	テーブルリスト追加
# 2017/03/08	Okuno	ColumnのPermissionが出力されない不具合を改修
#						出力項目にpermissionを追加
# 2017/04/05	Okuno	テーブルリストの参照先のEntry Modeを追加
# 2017/04/06	Okuno	テーブルリストの参照先のをcolfield-datasrcで判断するように変更
# 開発メモ
#-------------------------------------------------------------------------
# 引数に設定する順序
# 	$object_name
# 	$schema_name
# 	$server_name
# 	$data
# 	$qual
# 	$flag
# 
##########################################################################
use utf8;
binmode STDIN, ':encoding(cp932)';
binmode STDOUT, ':encoding(cp932)';
binmode STDERR, ':encoding(cp932)';

# 引数を取得
$input_dir = $ARGV[0];
$output_prefix = $ARGV[1];

# 引数をチェック
if($input_dir eq ""){
	print "【使い方】\n";
	print "03_remedyDefFormat.pl 【入力フォルダ】 【出力ファイルプレフィックス】\n";
	exit(1);
}
print "03_remedyDefFormat.pl 実行開始\n";

# 初期値設定
$tag20 = "\\\\20\\\\4\\\\";			# タグ20はフィールド論理名
$tag3 = "\\\\3\\\\41\\\\";
$tag21 = "\\\\21\\\\41\\\\";
$tag22 = "\\\\22\\\\4\\\\";
$tag24 = "\\\\22\\\\4\\\\";
$tag28 = "\\\\22\\\\6\\\\";
$tag40 = "\\\\40\\\\41\\\\";
$tag41 = "\\\\41\\\\40\\\\";
$tag62 = "\\\\62\\\\6\\\\";
$tag143 = "\\\\143\\\\40\\\\";
$tag170 = "\\\\170\\\\40\\\\";
$tag220 = "\\\\220\\\\40\\\\";


$tag206 = "\\\\206\\\\4\\\\";		# タグ206はview論理名
$tag207 = "\\\\207\\\\4\\\\";

# 出力ファイルオープン
open(OUT_FORM,">:encoding(cp932)"        , $output_prefix . "03_remedyDefFormat_0_form.dat");
open(OUT_ACTIVELINK,">:encoding(cp932)"  , $output_prefix . "03_remedyDefFormat_1_activeLink.dat");
open(OUT_FILTER,">:encoding(cp932)"      , $output_prefix . "03_remedyDefFormat_1_filter.dat");
open(OUT_CHARMENU,">:encoding(cp932)"    , $output_prefix . "03_remedyDefFormat_1_charMenu.dat");
open(OUT_ESCALATION,">:encoding(cp932)"  , $output_prefix . "03_remedyDefFormat_1_escalation.dat");
open(OUT_CONTAINER,">:encoding(cp932)"   , $output_prefix . "03_remedyDefFormat_1_container.dat");
open(OUT_AL_ACTION,">:encoding(cp932)"   , $output_prefix . "03_remedyDefFormat_2_al_action.dat");
open(OUT_FL_ACTION,">:encoding(cp932)"   , $output_prefix . "03_remedyDefFormat_2_fl_action.dat");
open(OUT_ES_ACTION,">:encoding(cp932)"   , $output_prefix . "03_remedyDefFormat_2_es_action.dat");
open(OUT_CT_REFERENCE,">:encoding(cp932)", $output_prefix . "03_remedyDefFormat_2_ct_reference.dat");
open(OUT_TABLE_LIST,">:encoding(cp932)"  , $output_prefix . "03_remedyDefFormat_3_table_list.dat");
open(OUT_WORK,">:encoding(cp932)"        , $output_prefix . "03_remedyDefFormat_work.dat");

$workInt = 0;

opendir(DIR, "$input_dir") or die;					# 入力フォルダオープン
@file = sort readdir(DIR);
foreach $input_file (@file){
    
    next if $input_file =~ /^\.{1,2}$/; # '.'や'..'も取れるので、スキップする
    next if $input_file !~ /^.+\.def$/; # フォーマット外は、スキップする
    
    # ファイル名を出力
    print OUT_WORK "---------------------\n";
    print OUT_WORK Encode::decode('cp932', $input_file) . "\n";
    
    # フルパスに変換
    $input_file = $input_dir . "\\" . $input_file;
	# ファイルオープン
	open(IN, "<:utf8", $input_file);
	while($line = <IN>){
		$skip_flag = 0;		# 同じオブジェクトを処理している場合、後ろの処理をスキップさせる
		###############################
		# begin schema句で処理開始
		###############################
		if($line =~ /^begin schema/){
			$schema_name = "";
			$line = <IN>;
			# schemaの設定値を取得する
			while($line =~ /: /){
				# 項目と値の取得
				$item = "$`";
				$value = "$'";
				chomp($item);
				chomp($value);
				$item =~ s/^ *(.*?) *$/$1/;
				
				# フォーム名の取得
				if($item =~ /^name/){
					$schema_name = $value;
					# すでに処理済みの場合はスキップ
					if(defined($syorizumi_object{'Form'}{$schema_name})){
						while($line !~ /^end/){
							$line = <IN>;
						}
						last;
					}else{
						$syorizumi_object{'Form'}{$schema_name}=1;
					}
				}
				
				# 項目の取得
				if ($schema_name ne ""){
					$schema{$schema_name}{$item} = $value;
				}
				$line = <IN>;
			}

			# schemaのendになるまで処理を続ける
			while($line !~ /^end/){
			
				# vuiの設定値を取得する
				if($line =~ /^vui/){
					%split_data = ();
					$vui = ();
					$work_display_prop = "";
					
					$line = <IN>;
					while($line =~ /: /){
						# 項目と値の取得
						$item = "$`";
						$value = "$'";
						chomp($item);
						chomp($value);
						$item =~ s/^ *(.*?) *$/$1/;
						
						# view名の取得
						if($item =~ /^name/){
							$vui_name = $value;
						}
						
						# display_propの場合
						if($item =~ /display-prop/){
							$work_display_prop = $work_display_prop . $value;
						}
						
						# 項目の取得
						$vui{$schema_name}{$item} = $value;
						
						# 次の行へ
						$line = <IN>;
					}
					# viewの論理名を取得
					if($work_display_prop =~ /$tag206.+$tag207/){
						@split_data = split(/\\/, "$&");
						$schema{$schema_name}{'name_jp'} = $split_data[4];
					}
				}
				
				# fieldの設定値を取得する
				elsif($line =~ /^field/){
					%split_data = ();
					%work_field = ();
					$work_enum_value = "";
					$work_enum_value_cnt = 0;
					$work_display_instance = "";
					
					# fieldの設定値を取得する
					$line = <IN>;
					while($line =~ /: /){
						# 項目と値の取得
						$item = "$`";
						$value = "$'";
						chomp($item);
						chomp($value);
						$item =~ s/^ *(.*?) *$/$1/;
						$value =~ s/\t//;
						
						# enum-value-numの場合⇒2行以上になるので、連結が必要
						if($item =~ /enum-value-num/){
							# 番号,値の取得
							$work_selection_no = substr($value, 0, index($value, "\\"));
							$work_selection_value = substr($value, index($value, "\\") + 1);
							
							# フィールド一覧用にデータを連結
							$work_enum_value = $work_enum_value . $work_selection_no . ":" . $work_selection_value . "\n";
							# 辞書用に配列に入れる
							$work_selection_no = $work_field{'id'} . ":" . $work_selection_no;
							$selection_dict{$schema_name}{$work_selection_no}=$work_selection_value;
						}
						# enum-valueの場合⇒2行以上になるので、連結が必要
						elsif($item =~ /enum-value/){
							$work_enum_value = $work_enum_value . $work_enum_value_cnt . ":" . $value . "\n";
							
							# 辞書用に配列に入れる
							$work_selection_no = $work_field{'id'} . ":" . $work_enum_value_cnt;
							$selection_dict{$schema_name}{$work_selection_no}=$value;
							
							$work_enum_value_cnt++;
						}
						# display-instanceの場合⇒2行以上になるので、連結が必要
						elsif($item =~ /display-instance/){
							$work_display_instance = $work_display_instance . $value;
						}
						elsif($item =~ /permission/){
							$work_field{$item} = join(",", $work_field{$item}, $value);
						}
						else{
							$work_field{$item} = $value;
						}
						
						# 次の行へ
						$line = <IN>;
					}
					#### ↑ ここでフィールド項目取得処理終了 ↑ ###
					
					# permissionの整形
					if($work_field{'permission'} ne ""){
						$work_field{'permission'} = substr($work_field{'permission'}, 1, length($work_field{'permission'}))
					}
					
					# enum-valueの整形
					if($work_enum_value ne ""){
						# エクセルのセル内で改行するため前後にダブルクオテーションをつける
						$work_enum_value = "\"" . $work_enum_value . "\"";
						$work_field{'enum_value'} = $work_enum_value
					}
					
					# display_instanceからフィールドの論理名を取得 ※ここが一部未解読！！！！！
					
					# ビューIDを取得
					&splitYen($work_display_instance, $disp_view_id);
					# 項目数を取得
					&splitYen($work_display_instance, $disp_item_cnt);
					# 項目数が0より大きければプロパティを取得していく
					while($disp_item_cnt gt 0){
						# プロパティ種別の数字を取得
						&splitYen($work_display_instance, $disp_control_char);
						
						# プロパティ種別 1 の場合
						if($disp_control_char eq 1){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 2 の場合
						elsif($disp_control_char eq 2){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 3 の場合
						elsif($disp_control_char eq 3){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 4 の場合
						elsif($disp_control_char eq 4){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_visible);
							$work_field{'visible'}=$disp_visible;
						}
						# プロパティ種別 5 の場合
						elsif($disp_control_char eq 5){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 7 の場合
						elsif($disp_control_char eq 7){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 8 の場合
						elsif($disp_control_char eq 8){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 9 の場合
						elsif($disp_control_char eq 9){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 11 の場合
						elsif($disp_control_char eq 11){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 14 の場合
						elsif($disp_control_char eq 14){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 14 の場合
						elsif($disp_control_char eq 16){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_work);
						}
						# プロパティ種別 未解読 の場合
						elsif( $disp_control_char eq 6 ||
						      $disp_control_char eq 10 ||
						      $disp_control_char eq 12 ||
						      $disp_control_char eq 13 ||
						      $disp_control_char eq 15 ||
						      $disp_control_char eq 17 || 
						      $disp_control_char eq 18 || 
						      $disp_control_char eq 19){
							&logOutput("ERROR", "disp_control_char=$disp_control_char", join("\t"
																	, $work_field{'name'}
																	, $work_field{'name_jp'}
																	, $work_field{'id'}
																	, "\n")
																	);
							$disp_item_cnt=0;
						}
						# プロパティ種別 20 の場合
						elsif( $disp_control_char eq 20){
							&splitYen($work_display_instance, $disp_work);
							&splitYen($work_display_instance, $disp_str_cnt);
							&getStringByByte('', $work_field{'name_jp'}, $work_display_instance, $disp_str_cnt);
							$disp_item_cnt=0;
						}
						# プロパティ種別 21以降はスルー
						else{
							$disp_item_cnt=0;
						}
						$disp_item_cnt--;
					}

					#if($work_display_instance =~ /$tag20.+$tag21/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag143/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag170/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag220/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag62/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag41/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag40/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag28/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag24/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}elsif($work_display_instance =~ /$tag20.+$tag22/){
					#	@split_data = split(/\\/, "$&");
					#	$work_field{'name_jp'} = $split_data[4];
					#	$disp_item_cnt=0;
					#}

					
					# コード変換
					#&replaceCodeField(@work_field);
					
					# Selection Dataが定義されていれば、別配列に保持しておく
					if(defined($work_field{'enum_value'})){
						$selection{$schema_name}{$work_field{'id'}}=$work_field{'enum_value'};
					}
					
					# カラムフィールドは構成されているテーブルのフィールドと参照先フォームでの参照先IDを設定しておく
					#
					# 例  CURE_AP_ApprovalRequest	536880912(T01ColZidouSyudouFlagのこと)
					#
					# $parentField{CURE_AP_ApprovalRequest}{536880912}=536870958(Table01SyouninsyaItiranのこと)
					# ⇒「CURE_AP_ApprovalRequestのT01ColZidouSyudouFlagは、Table01SyouninsyaItiranに属しているよ」というのがわかる
					#
					# $refer{CURE_AP_ApprovalRequest}{536880912}=536870919(CURE_AP_ApprovalRequestDetailのzZidouSyudouFlagのこと)
					# ⇒「CURE_AP_ApprovalRequestのT01ColZidouSyudouFlagは、参照先のフォームzZidouSyudouFlagから取得しているよ」というのがわかる(参照先フォームがどこなのかここではわからない)
					#
					if($work_field{'datatype'} eq 34){
						$parentField{$schema_name}{$work_field{'id'}}=$work_field{'colfield-parent'};
						$referField{$schema_name}{$work_field{'id'}}=$work_field{'colfield-datafield'};
						$datasrc{$schema_name}{$work_field{'id'}}=$work_field{'colfield-datasrc'};
					}
					
					# テーブルフィールドは参照先フォームを設定しておく
					# 
					# 例  CURE_AP_ApprovalRequest	536870958(Table01SyouninsyaItiranのこと)
					#
					# $tableField{CURE_AP_ApprovalRequest}{536870958}=CURE_AP_ApprovalRequestDetail
					# ⇒「CURE_AP_ApprovalRequestのTable01SyouninsyaItiranは、CURE_AP_ApprovalRequestDetailから取得しているよ」というのがわかる(参照先フォームがわかる)
					#
					if($work_field{'datatype'} eq 33){
						$tableField{$schema_name}{$work_field{'id'}}=$work_field{'tablefield-schema'};
					}
					
					# フィールド情報を入れる⇒フィールド情報で出力したいものは、ここで編集
					# $data{$schema_name}{$field{'id'}}が本当はいいけど、50音順のが見栄えが良い
					# 同じスキーマ内で同じnameは設定できないことは確認しているため、キー重複が発生して上書くことはないはず
					$field{$schema_name}{$work_field{'name'}}=join("\t"
																, $work_field{'name'}
																, $work_field{'name_jp'}
																, $work_field{'id'}
																, $work_field{'datatype'}
																, $work_field{'maxlength'}
																, $work_field{'option'}
																, $work_field{'visible'}
																, $work_field{'last-changed'}
																, $work_field{'timestamp'}
																, $work_field{'permission'}
																, $work_field{'enum_value'}
																);
					
					# 辞書用
					$field_dict{$schema_name}{$work_field{'id'}}=$work_field{'name'};
					$field_dict_name{$schema_name}{$work_field{'name'}}=$work_field{'id'};
					$field_dict_type{$schema_name}{$work_field{'id'}}=$work_field{'datatype'};
					$field_dict_option{$schema_name}{$work_field{'id'}}=$work_field{'option'};
				}
				else{
					# 次の行へ
					$line = <IN>;
				}
			}
			# Form件数をカウント
			$RESULT{'02_Form件数'}++;
		}
		###############################
		# begin active link句で処理開始
		###############################
		elsif($line =~ /^begin active link/){
			$if_serial_no = 1;
			$else_serial_no = 1;
			%al_item = ();
			%schema_name = ();
			$schema_cnt = 1;
			$work_actlink_query = "";
			$work_permission = "";
			$line = <IN>;
			# (active linkの間ループ) endになるまで処理を続ける
			while($line !~ /^end/){
				# active linkの属性を取得
				if($line =~ /: /){
					# 項目と値の取得
					$item = "$`";
					$value = "$'";
					chomp($item);
					chomp($value);
					$item =~ s/^ *(.*?) *$/$1/;
					
					# nameの場合
					if($item eq 'name'){
						# すでに処理済みの場合はスキップ
						if(defined($syorizumi_object{'ActiveLink'}{$value})){
							while($line !~ /^end/){
								$line = <IN>;
							}
							last;
						}else{
							$syorizumi_object{'ActiveLink'}{$value}=1;
						}
					}
					
					# 項目の取得
					# schema-nameの場合
					if($item eq 'schema-name'){
						$schema_name[$schema_cnt] = $value;
						$schema_cnt++;
					}
					# actlink-queryの場合、連結が必要
					elsif($item =~ /actlink-query/){
						$work_actlink_query = $work_actlink_query . $value;
					}
					# permissionの場合、連結が必要
					elsif($item =~ /permission/){
						$work_permission = $work_permission . $value;
					}
					# それ以外の場合
					else{
						$al_item{$item} = $value;
					}
				}
				##############################
				# ActiveLink If Actionsのデータ取得
				# action{}の部分
				##############################
				elsif($line =~ /^   action \{/){
					&formatAction($al_item{'name'}, "ActiveLink", "0 If Action", $if_serial_no);
					$if_serial_no++;
				}
				##############################
				# ActiveLink  Else Actionsのデータ取得
				##############################
				elsif($line =~ /^   else \{/){
					&formatAction($al_item{'name'}, "ActiveLink", "1 Else Action", $else_serial_no);
					$else_serial_no++;
				}
				
				# 次の行へ
				$line = <IN>;
			}
			# 連結したPermissionを設定
			$al_item{'permission'} = $work_permission;
			
			# 取得したActive Link情報をactiveLinkへ挿入
			for ($j = 1; $j < $schema_cnt; $j++) {
				$activeLink{$al_item{'name'} . "\t" . $schema_name[$j]}=join("\t"
									, $al_item{'timestamp'}
									, $schema_name[$j]
									, $al_item{'export-version'}
									, $al_item{'owner'}
									, $al_item{'last-changed'}
									, $al_item{'actlink-order'}
									, $al_item{'wk-conn-type'}
									, $al_item{'actlink-mask'}
									, $al_item{'actlink-manipulate'}
									, $al_item{'actlink-focus'}
									, $al_item{'actlink-control'}
									, $al_item{'actlink-query'}
									, $al_item{'enable'}
									, $al_item{'object-prop'}
									, $al_item{'errhandler-opt'}
									, $al_item{'errhandler-name'}
									, $al_item{'permission'}
									);
			}
			# ActiveLink件数をカウント
			$RESULT{'03_ActiveLink件数'}++;
		}
		
		
		###############################
		# begin filter句で処理開始
		###############################
		elsif($line =~ /^begin filter/){
			$if_serial_no  = 1;
			$else_serial_no  = 1;
			%fl_item = ();
			%schema_name = ();
			$schema_cnt = 1;
			$work_filter_query = "";
			$work_permission = "";
			$line = <IN>;
			# endになるまで処理を続ける
			while($line !~ /^end/){
				# filterの属性を取得
				if($line =~ /: /){
					# 項目と値の取得
					$item = "$`";
					$value = "$'";
					chomp($item);
					chomp($value);
					$item =~ s/^ *(.*?) *$/$1/;
					
					# nameの場合
					if($item eq 'name'){
						# すでに処理済みの場合はスキップ
						if(defined($syorizumi_object{'Filter'}{$value})){
							while($line !~ /^end/){
								$line = <IN>;
							}
							last;
						}else{
							$syorizumi_object{'Filter'}{$value}=1;
						}
					}
					
					# 項目の取得
					# schema-nameの場合
					if($item eq 'schema-name'){
						$schema_name[$schema_cnt] = $value;
						$schema_cnt++;
					}
					# filter-queryの場合
					elsif($item =~ /filter-query/){
						$work_filter_query = $work_filter_query . $value;
					}
					# permissionの場合、連結が必要
					elsif($item =~ /permission/){
						$work_permission = $work_permission . $value;
					}
					# それ以外の場合
					else{
						$fl_item{$item} = $value;
					}
				}
				##############################
				# If Actionsのデータ取得
				# action{}の部分
				##############################
				elsif($line =~ /^   action \{/){
					&formatAction($fl_item{'name'}, "Filter", "0 If Action", $if_serial_no);
					$if_serial_no++;
				}
				##############################
				# Else Actionsのデータ取得
				##############################
				elsif($line =~ /^   else \{/){
					&formatAction($fl_item{'name'}, "Filter", "1 Else Action", $else_serial_no);
					$else_serial_no++;
				}

				# 次の行へ
				$line = <IN>;
			}
			# 連結したPermissionを設定
			$fl_item{'permission'} = $work_permission;
			
			# 取得したFilter情報をfilterへ挿入
			for ($j = 1; $j < $schema_cnt; $j++) {
				$filter{$fl_item{'name'} . "\t" . $schema_name[$j]}=join("\t"
										, $fl_item{'timestamp'}
										, $schema_name[$j]
										, $fl_item{'export-version'}
										, $fl_item{'owner'}
										, $fl_item{'last-changed'}
										, $fl_item{'filter-order'}
										, $fl_item{'wk-conn-type'}
										, $fl_item{'filter-op'}
										, ''
										, ''
										, ''
										, $fl_item{'filter-query'}
										, $fl_item{'enable'}
										, $fl_item{'object-prop'}
										, $fl_item{'errhandler-opt'}
										, ''
										);
			}
			# Filter件数をカウント
			$RESULT{'04_Filter件数'}++;
		}
		
		
		###############################
		# begin char menu句で処理開始
		###############################
		elsif($line =~ /^begin char menu/){
			%cm_item = ();
			$line = <IN>;
			$work_char_menu = "";
			# endになるまで処理を続ける
			while($line !~ /^end/){
				if($line =~ /: /){
					# 項目と値の取得
					$item = "$`";
					$value = "$'";
					chomp($item);
					$value =~ s/[\r\n]//g;
					$item =~ s/^ *(.*?) *$/$1/;
					
					# char-menuの場合
					if($item =~ /char-menu/){
						# 項目の取得
						$work_char_menu = $value;
						
						# 次の行を取得
						$line = <IN>;
						if($line =~ /: /){
							$item = "$`";
							$value = "$'";
							chomp($item);
							$value =~ s/[\r\n]//g;
							$item =~ s/^ *(.*?) *$/$1/;
						}
						
						# nameの場合
						if($item eq 'name'){
							# すでに処理済みの場合はスキップ
							if(defined($syorizumi_object{'CharMenu'}{$value})){
								while($line !~ /^end/){
									$line = <IN>;
								}
								$skip_flag = 1;
								last;
							}else{
								$syorizumi_object{'CharMenu'}{$value}=1;
							}
						}
						
						# object-propになるまで処理続行
						while($item !~ /object-prop/){
							# 次の行がchar-menuの場合、先頭の\を削除して連結
							if($item =~ /char-menu/){
								$value =~ s/^\\+//;
								$work_char_menu = $work_char_menu . $value
							}
							# 次の行がchar-menuでない場合、連結
							else{
								$work_char_menu = $work_char_menu . $value
							}
							
							# 次の行を取得
							$line = <IN>;
							if($line =~ /: /){
								$item = "$`";
								$value = "$'";
								chomp($item);
								$value =~ s/[\r\n]//g;
								$item =~ s/^ *(.*?) *$/$1/;
							}
						}
						$cm_item{'char-menu'} = $work_char_menu;
					}
					# 項目の取得
					$cm_item{$item} = $value;
				}
				# 次の行へ
				$line = <IN>;
			}
			
			# 取得したChar Menu情報をcharMenuへ挿入
			if($skip_flag ne 1){
				$charMenu{$cm_item{'name'}}=join("\t"
										, $cm_item{'timestamp'}
										, $cm_item{'char-menu'}
										);
			}
			# Char Menu件数をカウント
			$RESULT{'05_Char Menu件数'}++;
		}
		
		
		###############################
		# begin escalation句で処理開始
		###############################
		elsif($line =~ /^begin escalation/){
			$if_serial_no  = 1;
			$else_serial_no  = 1;
			%es_item = ();
			%schema_name = ();
			$schema_cnt = 1;
			$work_escl_query = "";
			$work_permission = "";
			$line = <IN>;
			
			# endになるまで処理を続ける
			while($line !~ /^end/){
				# escalationの属性を取得
				if($line =~ /: /){
					# 項目と値の取得
					$item = "$`";
					$value = "$'";
					chomp($item);
					chomp($value);
					$item =~ s/^ *(.*?) *$/$1/;
					
					# nameの場合
					if($item eq 'name'){
						# すでに処理済みの場合はスキップ
						if(defined($syorizumi_object{'Escalation'}{$value})){
							while($line !~ /^end/){
								$line = <IN>;
							}
							last;
						}else{
							$syorizumi_object{'Escalation'}{$value}=1;
						}
					}
					
					# 項目の取得
					# schema-nameの場合
					if($item eq 'schema-name'){
						$schema_name[$schema_cnt] = $value;
						$schema_cnt++;
					}
					# escl-queryの場合
					elsif($item =~ /escl-query/){
						$work_escl_query = $work_escl_query . $value;
					}
					# permissionの場合、連結が必要
					elsif($item =~ /permission/){
						$work_permission = $work_permission . $value;
					}
					# それ以外の場合
					else{
						$es_item{$item} = $value;
					}
				}
				##############################
				# If Actionsのデータ取得
				# action{}の部分
				##############################
				elsif($line =~ /^   action \{/){
					&formatAction($es_item{'name'}, "Escalation", "0 If Action", $if_serial_no);
					$if_serial_no++;
				}
				##############################
				# Else Actionsのデータ取得
				##############################
				elsif($line =~ /^   else \{/){
					&formatAction($es_item{'name'}, "Escalation", "1 Else Action", $else_serial_no);
					$else_serial_no++;
				}
				
				# 次の行へ
				$line = <IN>;
			}
			# 連結したPermissionを設定
			$es_item{'permission'} = $work_permission;
			
			# 取得したEscaltion情報をescalationへ挿入
			for ($j = 1; $j < $schema_cnt; $j++) {
				$escalation{$es_item{'name'} . "\t" . $schema_name[$j]}=join("\t"
																				, $es_item{'timestamp'}
																				, $schema_name[$j]
																				, $es_item{'owner'}
																				, $es_item{'last-changed'}
																				, $es_item{'enable'}
																				, $es_item{'escl-tmType'}
																				, $es_item{'export-version'}
																				, $es_item{'escl-interval'}
																				, $es_item{'escl-monthday'}
																				, $es_item{'escl-weekday'}
																				, $es_item{'escl-hourmask'}
																				, $es_item{'escl-minute'}
																				, $es_item{'escl-query'}
																				, $es_item{'wk-conn-type'}
																				, $es_item{'object-prop'}
																				, $es_item{'permission'}
																			);
			}
			# Escalation件数をカウント
			$RESULT{'06_Escalation件数'}++;
		}
		
		###############################
		# begin container句で処理開始
		###############################
		elsif($line =~ /^begin container/){
			%ct_item = ();
			$line = <IN>;
			$work_permission = "";
			$ct_reference_serial_no = 1;
			# endになるまで処理を続ける
			while($line !~ /^end/){
				if($line =~ /: /){
						# 項目と値の取得
						$item = "$`";
						$value = "$'";
						chomp($item);
						chomp($value);
						$item =~ s/^ *(.*?) *$/$1/;
						
						# nameの場合
						if($item eq 'name'){
							# すでに処理済みの場合はスキップ
							if(defined($syorizumi_object{'Container'}{$value})){
								while($line !~ /^end/){
									$line = <IN>;
								}
								$skip_flag = 1;
								last;
							}else{
								$syorizumi_object{'Container'}{$value}=1;
							}
						}
						# permissionの場合、連結が必要
						elsif($item =~ /permission/){
							$work_permission = $work_permission . $value;
						}
						
						# 項目の取得
						$ct_item{$item} = $value;
				}
				##############################
				# referenceのデータ取得
				##############################
				elsif($line =~ /^reference \{/){
					%ct_reference_item = ();
					$line = <IN>;
					# 閉じ括弧まで処理を続ける
					while($line !~ /^\}/){
						if($line =~ /: /){
							# 項目と値の取得
							$item = "$`";
							$value = "$'";
							chomp($item);
							chomp($value);
							$item =~ s/^ *(.*?) *$/$1/;
							$value =~ s/[\r\n]//g;
							$value =~ s/\t/    /g;
							#$value_head = $split_data[0];
							
							# valueの場合
							if($item =~ /value/){
								# 項目の取得
								$work_value = $value;
								
								# 次の行を取得
								$line = <IN>;
								if($line =~ /: /){
									$item = "$`";
									$value = "$'";
									chomp($item);
									$value =~ s/[\r\n]//g;
									$item =~ s/^ *(.*?) *$/$1/;
								}
								
								# ref-groups or }になるまで処理続行
								while($item !~ /ref-groups/ && $line !~ /\}/){
									$work_value = $work_value . $value;
									# 次の行を取得
									$line = <IN>;
									if($line =~ /: /){
										$item = "$`";
										$value = "$'";
										chomp($item);
										$value =~ s/[\r\n]//g;
										$item =~ s/^ *(.*?) *$/$1/;
									}
								}
								$ct_reference_item{'value'} = $work_value;
							}
							# 項目の取得
							$ct_reference_item{$item} = $value;
						}
						# 次の行へ
						if($line !~ /\}/){
							$line = <IN>;
						}
					}
					
					# Web Serviceはスキップ
					if($ct_item{'type'} != 5){
						# 取得したEscaltion情報をescalationへ挿入
						$ct_reference{$ct_item{'name'} . "\t" . $ct_reference_serial_no}=join("\t"
																							, $ct_reference_item{'object'}
																							, $ct_reference_item{'type'}
																							, $ct_reference_item{'datatype'}
																							, $ct_reference_item{'label'}
																							, $ct_reference_item{'value'}
																							);
						# reference{}の個数をインクリメント
						$ct_reference_serial_no++;
					}
				}
				# 次の行へ
				$line = <IN>;
			}
			# 連結したPermissionを設定
			$ct_item{'permission'} = $work_permission;
			
			# 取得したContainer情報をcontainerへ挿入
			if($skip_flag ne 1){
				$container{$ct_item{'name'}}=join("\t"
									, $ct_item{'type'}
									, $ct_item{'timestamp'}
									, $ct_item{'owning-obj'}
									, $ct_item{'enable'}
									, $ct_item{'permission'}
									);
			}
			# Container件数をカウント
			$RESULT{'07_Container件数'}++;
		}


		###############################
		# なんでもないとき
		###############################
		else{
			# 次の行へ(whileで読込み)
		}
	}
	close(IN);
	# 入力ファイル数をカウント
	$RESULT{'01_入力ファイル数'}++;
}
closedir(DIR);


###############################
# フォーム/テーブルリストの出力
###############################
if (%field ne "0"){
	# ヘッダー出力(フォーム)
	print OUT_FORM join("\t"
						, "画面物理名"
						, "画面論理名"
						, "フィールド名"
						, "フィールドラベル名"
						, "ID"
						, "タイプ"
						, "長さ"
						, "入力モード"
						, "表示/非表示"
						, "最終更新者"
						, "タイムスタンプ"
						, "permission"
						, "Selectionデータ"
						)."\n";
						
	# ヘッダー出力(テーブルリスト)
	print OUT_TABLE_LIST join("\t"
						, "画面物理名"
						, "画面論理名"
						, "テーブルラベル名"
						, "テーブルID"
						, "フィールド名"
						, "フィールドラベル名"
						, "タイプ"
						, "ID"
						, "表示/非表示"
						, "参照先画面物理名"
						, "参照先画面論理名"
						, "参照先フィールド名"
						, "参照先フィールドID"
						, "参照先フィールドタイプ"
						, "参照先エントリモード"
						)."\n";
						
	# データ出力
	foreach $firstkey ( sort keys %field ){
		$firstkeylist{$firstkey}=1;
		foreach $secondkey ( sort keys %{$field{$firstkey}} ){
			$secondkeylist{$secondkey}=1;
		}
	}
	foreach $firstkey ( sort keys %firstkeylist ){
		foreach $secondkey ( sort keys %secondkeylist ){
			if($field{$firstkey}{$secondkey} ne ""){
				
				# データを分解
				@split_data = split(/\t/, $field{$firstkey}{$secondkey});
				
				# データタイプがColumnの場合、Selectionデータを取得する
				if($split_data[3] eq 34){
					$parent=$parentField{$firstkey}{$split_data[2]};	# 構成されているテーブルIDを取得
					$refer=$referField{$firstkey}{$split_data[2]};		# 参照先IDを取得
					if(defined($selection{$tableField{$firstkey}{$parent}}{$refer})){
						# Selectionデータを設定
						$split_data[10] = $selection{$tableField{$firstkey}{$parent}}{$refer};
					}
					# テーブルリスト出力
					# データソースによって、参照先が異なる
					# datasrc=0 のとき、参照先フォームから取得
					if($datasrc{$firstkey}{$split_data[2]} eq 0){
						$refer_schema           = $tableField{$firstkey}{$parent};
						$refer_schema_name      = $schema{$tableField{$firstkey}{$parent}}{'name_jp'};
						$refer_field_name       = $field_dict{$tableField{$firstkey}{$parent}}{$refer};
						$refer_field_id         = $refer;
						$refer_field_type       = &replaceDataType($firstkey, $field_dict_type{$tableField{$firstkey}{$parent}}{$refer});
						$refer_field_entry_mode = &replaceEntryMode($firstkey, $field_dict_option{$tableField{$firstkey}{$parent}}{$refer});
					}
					# datasrc=1 のとき、カラムのあるフォームから取得
					elsif($datasrc{$firstkey}{$split_data[2]} eq 1){
						$refer_schema           = $firstkey;
						$refer_schema_name      = $schema{$firstkey}{'name_jp'};
						$refer_field_name       = $field_dict_name{$firstkey}{$refer};
						$refer_field_id         = $refer;
						$refer_field_type       = &replaceDataType($firstkey, $field_dict_type{$firstkey}{$refer});
						$refer_field_entry_mode = &replaceEntryMode($firstkey, $field_dict_option{$firstkey}{$refer});
					}
					# それ以外はワーニング
					else{
						&logOutput("WARNING", "テーブルリストの出力", "データソースが想定外です スキーマ名=$firstkey,フィールドID=$split_data[2],データソース=$datasrc{$firstkey}{$split_data[1]}");
					}
					print OUT_TABLE_LIST join("\t"
									, $firstkey
									, $schema{$firstkey}{'name_jp'}
									, $field_dict{$firstkey}{$parent}
									, $parent
									, $split_data[0]
									, $split_data[1]
									, &replaceDataType($firstkey, $split_data[3])
									, $split_data[2]
									, &replaceTrueFalse($firstkey, $split_data[6])
									, $refer_schema
									, $refer_schema_name
									, $refer_field_name
									, $refer_field_id
									, $refer_field_type
									, $refer_field_entry_mode
									)."\n";
				}
				# 出力処理
				print OUT_FORM join("\t"
									, $firstkey
									, $schema{$firstkey}{'name_jp'}
									, $split_data[0]
									, $split_data[1]
									, $split_data[2]
									, &replaceDataType($firstkey, $split_data[3])
									, $split_data[4]
									, &replaceEntryMode($firstkey, $split_data[5])
									, &replaceTrueFalse($firstkey, $split_data[6])
									, $split_data[7]
									, &replaceTimestamp($firstkey, $split_data[8])
									, $split_data[9]
									, &replaceDefault($firstkey, $split_data[10])
									)."\n";
			}
		}
	}
}

###############################
# Active Linkの出力
###############################
if (%activeLink ne "0"){
	# ヘッダー出力
	print OUT_ACTIVELINK join("\t"
						, "オブジェクト名"
						, "オブジェクト種類"
						, "タイムスタンプ"
						, "スキーマ名"
						, "export-version"
						, "所有者"
						, "最終更新者"
						, "order"
						, "wk-conn-type"
						, "Execution Options"
						, "Field Manipulate"
						, "focus(Field)"
						, "control(Button/Menu Field)"
						, "Run If"
						, "[0]disable/[1]enable"
						, "object-prop"
						, "errhandler-opt"
						, "errhandler-name"
						, "permission"
						)."\n";
	# データ出力
	foreach $key (sort keys %activeLink){
		# キーの分解
		@split_key = split(/\t/, $key);
		
		# データの分解
		@split_data = split(/\t/, $activeLink{$key});
		print OUT_ACTIVELINK join("\t"
									, $split_key[0]
									, "Active Link"
									, &replaceTimestamp($split_key[0],$split_data[0])
									, $split_data[1]
									, $split_data[2]
									, $split_data[3]
									, $split_data[4]
									, $split_data[5]
									, $split_data[6]
									, &replaceActLinkMask($split_key[0], $split_data[7], 0)
									, &replaceActLinkMask($split_key[0], $split_data[7], 1)
									, &replaceIdtoName($split_key[0], $split_data[1], $split_data[9])
									, &replaceIdtoName($split_key[0], $split_data[1], $split_data[10])
									, &formatQualification($split_data[11], $split_key[0], $split_key[1], $split_key[1], 1)
									, &replaceEnable($split_key[0], $split_data[12])
									, $split_data[13]
									, $split_data[14]
									, $split_data[15]
									, $split_data[16]
									)."\n";
	}
}
###############################
# Filterの出力
###############################
if (%filter ne "0"){
	# ヘッダー出力
	print OUT_FILTER join("\t"
						, "オブジェクト名"
						, "オブジェクト種類"
						, "タイムスタンプ"
						, "スキーマ名"
						, "export-version"
						, "所有者"
						, "最終更新者"
						, "order"
						, "wk-conn-type"
						, "Execution Options"
						, "Field Manipulate"
						, "focus(Field)"
						, "control(Button/Menu Field)"
						, "Run If"
						, "[0]disable/[1]enable"
						, "object-prop"
						, "errhandler-opt"
						, "errhandler-name"
						, "permission"
						)."\n";
	# データ出力
	foreach $key (sort keys %filter){
		# キーの分解
		@split_key = split(/\t/, $key);
		
		# データの分解
		@split_data = split(/\t/, $filter{$key});
		print OUT_FILTER join("\t"
								, $split_key[0]
								, "Filter"
								, &replaceTimestamp($split_key[0], $split_data[0])
								, $split_data[1]
								, $split_data[2]
								, $split_data[3]
								, $split_data[4]
								, $split_data[5]
								, $split_data[6]
								, &replaceFilterMask($split_key[0], $split_data[7])
								, $split_data[8]
								, $split_data[9]
								, $split_data[10]
								, &formatQualification($split_data[11], $split_key[0], $split_key[1], $split_key[1], 0)
								, &replaceEnable($split_key[0], $split_data[12])
								, $split_data[13]
								, $split_data[14]
								, $split_data[15]
								, $split_data[16]
								)."\n";
	}
}
###############################
# Char Menuの出力
###############################
if (%charMenu ne "0"){
	# ヘッダー出力
	print OUT_CHARMENU join("\t"
						, "オブジェクト名"
						, "オブジェクト種類"
						, "タイムスタンプ"
						, "メニュー"
						)."\n";
	# データ出力
	foreach $key (sort keys %charMenu){
		# キーの分解
		@split_key = split(/\t/, $key);
		
		# データの分解
		@split_data = split(/\t/, $charMenu{$key});
		print OUT_CHARMENU join("\t"
								, $split_key[0]
								, "Char Menu"
								, &replaceTimestamp($split_key[0], $split_data[0])
								, $split_data[1]
								)."\n";
		
	}
}
###############################
# Escalationの出力
###############################
if (%escalation ne "0"){
	# ヘッダー出力
	print OUT_ESCALATION join("\t"
						, "オブジェクト名"
						, "オブジェクト種類"
						, "タイムスタンプ"
						, "スキーマ名"
						, "所有者"
						, "最終更新者"
						, "enable/disable"
						, "escl-tmType"
						, "export-version"
						, "escl-interval"
						, "escl-monthday"
						, "escl-weekday"
						, "escl-hourmask"
						, "escl-minute"
						, "Run If"
						, "wk-conn-type"
						, "object-prop"
						, "permission"
						)."\n";
	# データ出力
	foreach $key (sort keys %escalation){
		# キーの分解
		@split_key = split(/\t/, $key);
		
		# データの分解
		@split_data = split(/\t/, $escalation{$key});
		print OUT_ESCALATION join("\t"
								, $split_key[0]
								, "Escalation"
								, &replaceTimestamp($split_key[0], $split_data[0])
								, $split_data[1]
								, $split_data[2]
								, $split_data[3]
								, &replaceEnable($split_key[0], $split_data[4])
								, &replaceEscalationTmType($split_key[0], $split_data[5])
								, $split_data[6]
								, $split_data[7]
								, &replaceEscalationMonthday($split_key[0], $split_data[8])
								, &replaceEscalationWeekday($split_key[0], $split_data[9])
								, &replaceEscalationHourmask($split_key[0], $split_data[10])
								, $split_data[11]
								, &formatQualification($split_data[12], $split_key[0], $split_key[1], $split_key[1], 1)
								, $split_data[13]
								, $split_data[14]
								, $split_data[15]
								)."\n";
	}
}
###############################
# Containerの出力
###############################
if (%container ne "0"){
	# ヘッダー出力
	print OUT_CONTAINER join("\t"
						, "オブジェクト名"
						, "オブジェクト種類"
						, "タイムスタンプ"
						, "所有オブジェクト"
						, "permission"
						)."\n";
	# データ出力
	foreach $key (sort keys %container){
		# キーの分解
		@split_key = split(/\t/, $key);
		
		# データの分解
		@split_data = split(/\t/, $container{$key});
		
		# 所有オブジェクトの加工
		if($split_data[2] ne ""){
			&splitYen($split_data[2], $item);
			&splitYen($split_data[2], $item);
			&splitYen($split_data[2], $item);
			$split_data[2] = substr($split_data[2], 0, $item);
		}
		
		print OUT_CONTAINER join("\t"
								, $split_key[0]
								, &replaceContainerType($split_key[0], $split_data[0])
								, &replaceTimestamp($split_key[0], $split_data[1])
								, $split_data[2]
								, $split_data[4]
								)."\n";
	}
}

###############################
# Active Link actionの出力
###############################
if (%al_action ne "0"){
	&funcOutPutAction("ActiveLink", OUT_AL_ACTION, \%al_action);
}

###############################
# Filter actionの出力
###############################
if (%fl_action ne "0"){
	&funcOutPutAction("Filter", OUT_FL_ACTION, \%fl_action);
}

###############################
# Escalation actionの出力
###############################
if (%es_action ne "0"){
	&funcOutPutAction("Escalation", OUT_ES_ACTION, \%es_action);
}

###############################
# Container Referenceの出力
###############################
if (%ct_reference ne "0"){
	# ヘッダー出力
	print OUT_CT_REFERENCE join("\t"
						, "オブジェクト名"
						, "通番"
						, "参照オブジェクト名"
						, "参照オブジェクトタイプ"
						, "データタイプ"
						, "ラベル"
						, "値"
						)."\n";
	# データ出力
	foreach $key (sort keys %ct_reference){
		# キーの分解
		@split_key = split(/\t/, $key);
		
		# データの分解
		@split_data = split(/\t/, $ct_reference{$key});
		print OUT_CT_REFERENCE join("\t"
								, $split_key[0]
								, $split_key[1]
								, $split_data[0]
								, &replaceCtReferenceType($split_key[0], $split_data[1])
								, $split_data[2]
								, $split_data[3]
								, &replaceCtReferenceValue($split_key[0], $split_data[4])
								)."\n";
	}
}

close(OUT_FORM);
close(OUT_ACTIVELINK);
close(OUT_FILTER);
close(OUT_CHARMENU);
close(OUT_ESCALATION);
close(OUT_CONTAINER);
close(OUT_AL_ACTION);
close(OUT_FL_ACTION);
close(OUT_ALG_REFERENCE);
close(OUT_TABLE_LIST);
close(OUT_WORK);

print "----------------------------------------------------------------------\n";

# ログの出力
foreach $key (sort keys %RESULT){
	printf "$key = $RESULT{$key}\n";
}

print "----------------------------------------------------------------------\n";
print "03_remedyDefFormat.pl 実行終了\n";

###################################################################################################################################




################
# 置換系関数   #
################

# 104系の置換
sub funcDecode104{
	my $target = $_[0];		# 演算子を意味する数字
	
	if($target eq 1){
		$loop_cnt++;
		return "calc \+";
	}elsif($target eq 2){
		$loop_cnt++;
		return "calc \-";
	}elsif($target eq 3){
		$loop_cnt++;
		return "calc \*";
	}elsif($target eq 4){
		$loop_cnt++;
		return "calc \/";
	}elsif($target eq 6){
		return "calc \-\-";
	}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "funcDecode104", "文字列=$target");
	}
	return 0
}

# 105系の置換
sub funcDecode105{
	my $target = $_[0];	# 関数の種類
	
	if(   $target eq 1){   return "DATE";}
	elsif($target eq 2){   return "TIME";}
	elsif($target eq 3){   return "MONTH";}
	elsif($target eq 4){   return "DAY";}
	elsif($target eq 5){   return "YEAR";}
	elsif($target eq 6){   return "WEEKDAY";}
	elsif($target eq 10){  return "TRUNC";}
	elsif($target eq 11){  return "ROUND";}
	elsif($target eq 13){  return "LENGTH";}
	elsif($target eq 16){  return "SUBSTR";}
	elsif($target eq 17){  return "LEFT";}
	elsif($target eq 18){  return "RIGHT";}
	elsif($target eq 21){  return "LPAD";}
	elsif($target eq 23){  return "REPLACE";}
	elsif($target eq 24){  return "STRSTR";}
	elsif($target eq 27){  return "COLSUM";}
	elsif($target eq 28){  return "COLCOUNT";}
	elsif($target eq 32){  return "DATEADD";}
	elsif($target eq 33){  return "DATEDIFF";}
	elsif($target eq 40){  return "LENGTHC";}
	elsif($target eq 41){  return "LEFTC";}
	elsif($target eq 42){  return "RIGHTC";}
	elsif($target eq 43){  return "LPADC";}
	elsif($target eq 46){  return "SUBSTRC";}
	elsif($target eq 51){  return "SELECTEDROWCOUNT";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "funcDecode105", "文字列=$target");
	}
	return 0
}

# 演算子の置換
sub replaceOperator{
	my $target = $_[0];	# 演算子を意味する数字
	
	if(   $target eq 1){  return "=";}
	elsif($target eq 2){  return ">";}
	elsif($target eq 3){  return ">=";}
	elsif($target eq 4){  return "<";}
	elsif($target eq 5){  return "<=";}
	elsif($target eq 6){  return "!=";}
	elsif($target eq 7){  return "LIKE";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceOperator", "文字列=$target");
	}
	return 0
}

# keywordの置換
sub replaceKeyword{
	my $target = $_[0];	# keywordを意味する数字
	
	if(   $target eq 0){  return "\$DEFAULT\$";}
	elsif($target eq 1){  return "\$USER\$";}
	elsif($target eq 2){  return "\$TIMESTAMP\$";}
	elsif($target eq 4){  return "\$DATE\$";}
	elsif($target eq 5){  return "\$SCHEMA\$";}
	elsif($target eq 6){  return "\$SERVER\$";}
	elsif($target eq 9){  return "\$OPERATION\$";}
	elsif($target eq 13){ return "\$LASTID\$";}
	elsif($target eq 14){ return "\$LASTCOUNT\$";}
	elsif($target eq 16){ return "\$VUI\$";}
	elsif($target eq 22){ return "\$CLIENT-TYPE\$";}
	elsif($target eq 24){ return "\$ROWSELECTED\$";}
	elsif($target eq 29){ return "\$HOMEURL\$";}
	elsif($target eq 31){ return "\$EVENTTYPE\$";}
	elsif($target eq 33){ return "\$CURRENTWINID\$";}
	elsif($target eq 39){ return "\$SERVERTIMESTAMP\$";}
	elsif($target eq 40){ return "\$GROUPIDS\$";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceKeyword", "文字列=$target");
	}
	return 0
}

# 関数の置換
sub replaceFunc{
	my $target = $_[0];		# 関数を意味する数字
	
	if(   $target eq 1){  return "DATE";}
	elsif($target eq 2){  return "TIME";}
	elsif($target eq 3){  return "MONTH";}
	elsif($target eq 4){  return "DAY";}
	elsif($target eq 5){  return "YEAR";}
	elsif($target eq 6){  return "WEEKDAY";}
	elsif($target eq 10){ return "TRUNC";}
	elsif($target eq 11){ return "ROUND";}
	elsif($target eq 13){ return "LENGTH";}
	elsif($target eq 16){ return "SUBSTR";}
	elsif($target eq 17){ return "LEFT";}
	elsif($target eq 18){ return "RIGHT";}
	elsif($target eq 21){ return "LPAD";}
	elsif($target eq 23){ return "REPLACE";}
	elsif($target eq 24){ return "STRSTR";}
	elsif($target eq 27){ return "COLSUM";}
	elsif($target eq 28){ return "COLCOUNT";}
	elsif($target eq 32){ return "DATEADD";}
	elsif($target eq 33){ return "DATEDIFF";}
	elsif($target eq 40){ return "LENGTHC";}
	elsif($target eq 41){ return "LEFTC";}
	elsif($target eq 42){ return "RIGHTC";}
	elsif($target eq 43){ return "LPADC";}
	elsif($target eq 46){ return "SUBSTRC";}
	elsif($target eq 51){ return "SELECTEDROWCOUNT";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceFunc", "文字列=$target");
	}
	return 0
}

# If No Requests Matchのコード変換
sub replaceIfNoReqMatch{
	my $target = $_[0];		# 関数を意味する数字
	
	if(   $target eq 1){  return "Display 'No Match' Error";}
	elsif($target eq 2){  return "Set Fields to \$NULL\$";}
	elsif($target eq 3){  return "Take No Action";}
	elsif($target eq 4){  return "Create a New Request";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceIfNoReqMatch", "文字列=$target");
	}
	return 0
}

# If Multiple Requests Matchのコード変換
sub replaceIfMulReqMatch{
	my $target = $_[0];		# 関数を意味する数字
	
	if(   $target eq 1){  return "Display 'No Match' Error";}
	elsif($target eq 2){  return "Set Fields to \$NULL\$";}
	elsif($target eq 3){  return "Use First Matching Request";}
	elsif($target eq 4){  return "Display a List";}
	elsif($target eq 5){  return "Modify All Matching Requests";}
	elsif($target eq 6){  return "Take No Action";}
	elsif($target eq 7){  return "Use First Matching Request Based On Locale";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceIfNoReqMatch", "文字列=$target");
	}
	return 0
}

# If Any Requests Matchのコード変換
sub replaceIfAnyReqMatch{
	my $target = $_[0];		# 関数を意味する数字
	
	if(   $target eq 1){  return "Display 'Any Match' Error";}
	elsif($target eq 3){  return "Modify First Matching Request";}
	elsif($target eq 5){  return "Modify All Matching Requests";}
	elsif($target eq 6){  return "Take No Action";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceIfNoReqMatch", "文字列=$target");
	}
	return 0
}

### dataTypeコード変換用の関数 ###
sub replaceDataType{
	my $object_name = $_[0];	# オブジェクト名
	my $dataType = $_[1];		# タイプ
	if($dataType eq ""){}
	elsif($dataType eq 2){  $dataType = "Integer";}
	elsif($dataType eq 3){  $dataType = "Real";}
	elsif($dataType eq 4){  $dataType = "Character";}
	elsif($dataType eq 5){  $dataType = "Diary";}
	elsif($dataType eq 6){  $dataType = "Selection";}
	elsif($dataType eq 7){  $dataType = "Date/Time";}
	elsif($dataType eq 10){ $dataType = "Decimal";}
	elsif($dataType eq 11){ $dataType = "Attachment";}
	elsif($dataType eq 13){ $dataType = "Date";}
	elsif($dataType eq 14){ $dataType = "Time";}
	elsif($dataType eq 31){ $dataType = "Trim";}
	elsif($dataType eq 32){ $dataType = "Control";}
	elsif($dataType eq 33){ $dataType = "Table";}
	elsif($dataType eq 34){ $dataType = "Column";}
	elsif($dataType eq 35){ $dataType = "Panel";}
	elsif($dataType eq 36){ $dataType = "Panel Holder";}
	elsif($dataType eq 37){ $dataType = "Attachment Pool";}
	elsif($dataType eq 42){ $dataType = "View";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceDataType", "オブジェクト名=$object_name,文字列=$dataType");
	}
	return($dataType);
}

### EntryModeコード変換用の関数 ###
sub replaceEntryMode{
	my $object_name = $_[0];	# オブジェクト名
	my $entryMode = $_[1];		# エントリーモード
	# optionの置換 4はボタン系っぽい
	if($entryMode eq ""){}
	elsif($entryMode eq 1){ $entryMode = "Required";}
	elsif($entryMode eq 2){ $entryMode = "Optional";}
	elsif($entryMode eq 3){ $entryMode = "System";}
	elsif($entryMode eq 4){ $entryMode = "";}
	# それ以外はエラー
	else{
		&logOutput("ERROR", "replaceEntryMode", "オブジェクト名=$object_name,文字列=$entryMode");
	}
	return($entryMode);
}

### defaultコード変換用の関数 ###
sub replaceDefault{
	my $object_name = $_[0];	# オブジェクト名
	my $target = $_[1];			# 置換対象文字列
	my $match = "";				# マッチング文字列
	my $int = 0;
	while($target =~ /\$-[0-9]+\$/){
		$match = "$&";
		
		if   ($match =~ /\$-1\$/){ $target =~ s/\Q$match\E/\$USER\$/;}
		elsif($match =~ /\$-2\$/){ $target =~ s/\Q$match\E/\$DATE\$/;}
		elsif($match =~ /\$-4\$/){ $target =~ s/\Q$match\E/\$TIMESTAMP\$/;}
		elsif($match =~ /\$-5\$/){ $target =~ s/\Q$match\E/\$SCHEMA\$/;}
		elsif($match =~ /\$-6\$/){ $target =~ s/\Q$match\E/\$SERVER\$/;}
		elsif($match =~ /\$-9\$/){ $target =~ s/\Q$match\E/\$OPERATION\$/;}
		elsif($match =~ /\$-13\$/){ $target =~ s/\Q$match\E/\$LASTID\$/;}
		elsif($match =~ /\$-14\$/){ $target =~ s/\Q$match\E/\$LASTCOUNT\$/;}
		elsif($match =~ /\$-16\$/){ $target =~ s/\Q$match\E/\$VUI\$/;}
		elsif($match =~ /\$-22\$/){ $target =~ s/\Q$match\E/\$CLIENT-TYPE\$/;}
		elsif($match =~ /\$-24\$/){ $target =~ s/\Q$match\E/\$ROWSELECTED\$/;}
		elsif($match =~ /\$-29\$/){ $target =~ s/\Q$match\E/\$HOMEURL\$/;}
		elsif($match =~ /\$-31\$/){ $target =~ s/\Q$match\E/\$EVENTTYPE\$/;}
		elsif($match =~ /\$-39\$/){ $target =~ s/\Q$match\E/\$SERVERTIMESTAMP\$/;}
		elsif($match =~ /\$-40\$/){ $target =~ s/\Q$match\E/\$GROUPIDS\$/;}
		else{
			&logOutput("WARNING", "replaceDefault", "置換できませんでした オブジェクト名=$object_name,マッチング文字列=$match");
			last;
		}
	}
	return($target);
}

### timestampコード変換用の関数 ###
sub replaceTimestamp{
	my $object_name = $_[0];	# オブジェクト名
	my $timestamp = $_[1];		# UNIX日付
	
	if($timestamp ne ""){ 
		($sec,$min,$hh,$dd,$mm,$yy,$weak,$yday,$opt) = localtime($timestamp);
		$yy+= 1900;
		$mm+= 1;
		$timestamp="$yy/$mm/$dd $hh:$min:$sec"; 
	}
	
	return($timestamp);
}

### enable/disableコード変換用の関数 ###
sub replaceEnable{
	my $object_name = $_[0];	# オブジェクト名
	my $enable = $_[1];			# Enable/Disable
	
	if($enable ne ""){
		if(   $enable eq 0){ $enable = "Disable"; }
		elsif($enable eq 1){ $enable = "Enable"; }
		# それ以外はエラー
		else{
			&logOutput("ERROR", "replaceEnable", "オブジェクト名=$object_name,文字列=$enable");
		}
	}
	
	return($enable);
}

### True/Falseコード変換用の関数 ###
sub replaceTrueFalse{
	my $object_name = $_[0];	# オブジェクト名
	my $true_false = $_[1];		# True/False
	
	if($true_false ne ""){
		if(   $true_false eq 0){ $true_false = "False"; }
		elsif($true_false eq 1){ $true_false = "True"; }
		# それ以外はエラー
		else{
			&logOutput("ERROR", "replaceTrueFalse", "オブジェクト名=$object_name,文字列=$true_false");
		}
	}
	
	return($true_false);
}



################################
# idコード変換用の関数         #
# idからフィールド名に変換する #
################################
sub replaceIdtoName{
	my $object_name = $_[0];	# オブジェクト名
	my $schema_name = $_[1];	# スキーマ名
	my $field_id = $_[2];		# フィールドID
	my $field_name = "";		# フィールド名
	
	# フィールドIDがない場合は抜ける
	if($field_id eq ""){
		return $field_id;
	}
	
	# スキーマにフィールドIDが登録されているか確認
	if(defined($field_dict{$schema_name}{$field_id})){
		# フィールド名を取得
		$field_name = $field_dict{$schema_name}{$field_id};
	}
	# 置換できなければ、フィールドID
	else{
		$field_name = $field_id;
		&logOutput("WARNING", "replaceIdtoName", "置換できませんでした オブジェクト名=$object_name,スキーマ名=$schema_name,フィールドID=$field_id");
	}
	return($field_name);
}

############################################
# idコード変換用(文字列中にある場合)の関数 #
# idからフィールド名に変換する             #
############################################
sub replaceIdtoNameSentence{
	my $object_name = $_[0];	# オブジェクト名
	my $schema_name = $_[1];	# スキーマ名
	my $sentence = $_[2];		# 置換対象文字列
	my $match = "";				# マッチング文字列
	my $field_id = "";			# フィールドID
	
	# マッチング分だけ置換
	while($sentence =~ /\$[0-9]+\$/){
		$match = "$&";
		$field_id = substr($match, 1, length($match)-2);
		if(defined($field_dict{$schema_name}{$field_id})){
			$sentence =~ s/$field_id/$field_dict{$schema_name}{$field_id}/;
		}
		# 置換できなけば、メッセージを出力
		else{
			&logOutput("WARNING", "replaceIdtoNameSentence", "置換できませんでした オブジェクト名=$object_name,スキーマ名=$schema_name,センテンス=$sentence,フィールドID=$field_id");
			last;
		}
	}
	return($sentence);
}

################################
# フィールド名変換用の関数     #
# フィールド名からidに変換する #
################################
sub replaceNametoId{
	my $object_name = $_[0];	# オブジェクト名
	my $schema_name = $_[1];	# スキーマ名
	my $field_name = $_[2];		# フィールドID
	my $field_id = "";			# フィールド名
	
	# フィールドIDがない場合は抜ける
	if($field_name eq ""){
		return 0;
	}
	# スキーマにフィールドIDが登録されているか確認
	if(defined($field_dict_name{$schema_name}{$field_name})){
		# idを取得
		$field_id = $field_dict_name{$schema_name}{$field_name};
	}
	# 置換できなければ、フィールド名
	else{
		$field_id = $field_name;
		&logOutput("WARNING", "replaceNametoId", "置換できませんでした オブジェクト名=$object_name,スキーマ名=$schema_name,フィールド名=$field_name");
	}
	return($field_id);
}

################################
# Selectionデータ変換用の関数  #
################################
sub replaceSelectionData{
	my $object_name = $_[0];	# オブジェクト名
	my $schema_name = $_[1];	# スキーマ名
	my $field_id = $_[2];		# フィールドID
	my $selection_no = $_[3];	# 番号
	my $selection_value = "";	# 値
	
	# カラムフィールドの場合は、取得元フォーム、フィールドに変換
	if(defined($referField{$schema_name}{$field_id})){
		
		# フィールドIDを変換
		$parent_field_id = $parentField{$schema_name}{$field_id};
		$field_id = $referField{$schema_name}{$field_id};
		# スキーマを変換
		$schema_name = $tableField{$schema_name}{$parent_field_id};
	}
	# 辞書用に整形
	$selection_no = $field_id . ":" . $selection_no;
	
	# スキーマにフィールドID:値が登録されているか確認
	if(defined($selection_dict{$schema_name}{$selection_no})){
		# フィールド名を取得
		$selection_value = $selection_dict{$schema_name}{$selection_no};
	}
	# 見つからない場合は、ID:番号
	else{
		$selection_value = $selection_no;
		&logOutput("WARNING", "replaceSelectionData", "置換できませんでした オブジェクト名=$object_name,スキーマ名=$schema_name,フィールドID=$field_id,セレクション番号=$selection_no");
	}
	return($selection_value);
}


### actlink-maskコード変換用の関数 ###
sub replaceActLinkMask{
	$object_name = $_[0];
	$mask = $_[1];
	$getFlag = $_[2];
	
	if($mask >= 0){
		$exe_option_no = $mask;
		$tmp = "";
		$tmp2 = "";
		if($exe_option_no  - 268435456 >= 0) {
			$tmp2 = join(",", "Drop", $tmp2);
			$exe_option_no = $exe_option_no  - 268435456;
		}
		if($exe_option_no  - 134217728 >= 0) {
			$tmp2 = join(",", "Drag", $tmp2);
			$exe_option_no = $exe_option_no  - 134217728;
		}
		if($exe_option_no  - 16777216 >= 0) {
			$tmp2 = join(",", "Hover On Field", $tmp2);
			$exe_option_no = $exe_option_no  - 16777216;
		}
		if($exe_option_no  - 8388608 >= 0) {
			$tmp2 = join(",", "Hover On Data", $tmp2);
			$exe_option_no = $exe_option_no  - 8388608;
		}
		if($exe_option_no  - 4194304 >= 0) {
			$tmp2 = join(",", "Hover On Label", $tmp2);
			$exe_option_no = $exe_option_no  - 4194304;
		}
		if($exe_option_no  - 2097152 >= 0) {
			$tmp2 = join(",", "Table Refresh", $tmp2);
			$exe_option_no = $exe_option_no  - 2097152;
		}
		if($exe_option_no  - 1048576 >= 0) {
			$tmp = join(",", "Event", $tmp);
			$exe_option_no = $exe_option_no  - 1048576;
		}
		if($exe_option_no  - 262144 >= 0) {
			$tmp = join(",", "Window Loaded", $tmp);
			$exe_option_no = $exe_option_no  - 262144;
		}
		if($exe_option_no  - 131072 >= 0) {
			$tmp = join(",", "Copy To New", $tmp);
			$exe_option_no = $exe_option_no  - 131072;
		}
		if($exe_option_no  - 65536 >= 0) {
			$tmp = join(",", "Un-Display", $tmp);
			$exe_option_no = $exe_option_no  - 65536;
		}
		if($exe_option_no  - 32768 >= 0) {
			$tmp = join(",", "Window Closed", $tmp);
			$exe_option_no = $exe_option_no  - 32768;
		}
		if($exe_option_no  - 16384 >= 0) {
			$tmp = join(",", "Window Open", $tmp);
			$exe_option_no = $exe_option_no  - 16384;
		}
		if($exe_option_no  - 8192 >= 0) {
			$tmp2 = join(",", "Gain Focus", $tmp2);
			$exe_option_no = $exe_option_no  - 8192;
		}
		if($exe_option_no  - 4096 >= 0) {
			$tmp = join(",", "After Submit", $tmp);
			$exe_option_no = $exe_option_no  - 4096;
		}
		if($exe_option_no  - 2048 >= 0) {
			$tmp = join(",", "After Modify", $tmp);
			$exe_option_no = $exe_option_no  - 2048;
		}
		if($exe_option_no  - 1024 >= 0) {
			$tmp = join(",", "Search", $tmp);
			$exe_option_no = $exe_option_no  - 1024;
		}
		if($exe_option_no  - 512 >= 0) {
			$tmp = join(",", "Set Default", $tmp);
			$exe_option_no = $exe_option_no  - 512;
		}
		if($exe_option_no  - 256 >= 0) {
			$tmp2 = join(",", "Lose Focus", $tmp2);
			$exe_option_no = $exe_option_no  - 256;
		}
		if($exe_option_no  - 128 >= 0) {
			$tmp2 = join(",", "Choice", $tmp2);
			$exe_option_no = $exe_option_no  - 128;
		}
		if($exe_option_no  - 16 >= 0) {
			$tmp = join(",", "Display", $tmp);
			$exe_option_no = $exe_option_no  - 16;
		}
		if($exe_option_no  - 8 >= 0) {
			$tmp = join(",", "Modify(AL)", $tmp);
			$exe_option_no = $exe_option_no  - 8;
		}
		if($exe_option_no  - 4 >= 0) {
			$tmp = join(",", "Submit(AL)", $tmp);
			$exe_option_no = $exe_option_no  - 4;
		}
		if($exe_option_no  - 2 >= 0) {
			$tmp2 = join(",", "Return", $tmp2);
			$exe_option_no = $exe_option_no  - 2;
		}
		if($exe_option_no  - 1 >= 0) {
			#$tmp = join(",", "ボタン", $tmp);
			$exe_option_no = $exe_option_no  - 1;
		}
		if($exe_option_no > 0) {
			&logOutput("ERROR", "replaceActLinkMask", "オブジェクト名=$object_name, mask=$mask");
			$mask = "Perlを見直してください"; 
			return($mask);
		}
		$tmp = substr($tmp, 0, length($tmp) - 1);
		$tmp2 = substr($tmp2, 0, length($tmp2) - 1);
	}
	
	# フラグがmaskの場合
	if($getFlag eq 0){
		$mask = $tmp;
	# フラグがmanipulateの場合
	}elsif($getFlag eq 1){
		$mask = $tmp2;
	# それ以外はWarning
	}else{
		&logOutput("ERROR", "replaceActLinkMask", "オブジェクト名=$object_name, getFlag=$getFlag");
		$mask = "Perlを見直してください"; 
	}

	return($mask);
}


### filter-opコード変換用の関数 ###
sub replaceFilterMask{
	$object_name = $_[0];	# オブジェクト名
	$mask = $_[1];
	
	# filter-opの置換
	if($mask >= 0){
		$exe_option_no = $mask;
		$tmp = "";
		
		if($exe_option_no  - 64 >= 0) {
			$tmp = "Service";
			$exe_option_no = $exe_option_no  - 64;
		}
		if($exe_option_no  - 16 >= 0) {
			$tmp = join(",", "Merge", $tmp);
			$exe_option_no = $exe_option_no  - 16;
		}
		if($exe_option_no  - 8 >= 0) {
			$tmp = join(",", "Delete", $tmp);
			$exe_option_no = $exe_option_no  - 8;
		}
		if($exe_option_no  - 4 >= 0) {
			$tmp = join(",", "Submit(FL)", $tmp);
			$exe_option_no = $exe_option_no  - 4;
		}
		if($exe_option_no  - 2 >= 0) {
			$tmp = join(",", "Modify(FL)", $tmp);
			$exe_option_no = $exe_option_no  - 2;
		}
		if($exe_option_no  - 1 >= 0) {
			$tmp = join(",", "Get Entry", $tmp);
			$exe_option_no = $exe_option_no  - 1;
		}
		if($exe_option_no > 0) {
			&logOutput("ERROR", "replaceFilterMask", "オブジェクト名=$object_name, exe_option_no=$exe_option_no");
			$mask = "Perlを見直してください"; 
			return($mask);
		}
		$tmp = substr($tmp, 0, length($tmp) - 1);
		$mask = $tmp; 
	}
	
	return($mask);
}


### escalation 時間インターバル コード変換用の関数 ###
sub replaceEscalationTmType{
	$object_name = $_[0];	# オブジェクト名
	$tmType = $_[1];
	
	if($tmType eq 1){ $tmType = "Interval";
	}elsif($tmType eq 2){ $tmType = "Time";
	}else{
		&logOutput("ERROR", "replaceEscalationTmType", "オブジェクト名=$object_name, tmType=$tmType");
		$tmType = "Perlを見直してください"; 
	}
	return($tmType);
}

### escalation 月 コード変換用の関数 ###
sub replaceEscalationMonthday{
	$object_name = $_[0];	# オブジェクト名
	$monthday = $_[1];
	
	# escl-monthdayの置換
	if($monthday ne ""){ 
		$exe_option_no = $monthday;
		$tmp = "";
		if($exe_option_no  - 1073741824 >= 0) {
			$tmp = join(",", "31", $tmp);
			$exe_option_no = $exe_option_no - 1073741824;
		}
		if($exe_option_no  - 536870912 >= 0) {
			$tmp = join(",", "30", $tmp);
			$exe_option_no = $exe_option_no - 536870912;
		}
		if($exe_option_no  - 268435456 >= 0) {
			$tmp = join(",", "29", $tmp);
			$exe_option_no = $exe_option_no - 268435456;
		}
		if($exe_option_no  - 134217728 >= 0) {
			$tmp = join(",", "28", $tmp);
			$exe_option_no = $exe_option_no - 134217728;
		}
		if($exe_option_no  - 67108864 >= 0) {
			$tmp = join(",", "27", $tmp);
			$exe_option_no = $exe_option_no - 67108864;
		}
		if($exe_option_no  - 33554432 >= 0) {
			$tmp = join(",", "26", $tmp);
			$exe_option_no = $exe_option_no - 33554432;
		}
		if($exe_option_no  - 16777216 >= 0) {
			$tmp = join(",", "25", $tmp);
			$exe_option_no = $exe_option_no - 16777216;
		}
		if($exe_option_no  - 8388608 >= 0) {
			$tmp = join(",", "24", $tmp);
			$exe_option_no = $exe_option_no - 8388608;
		}
		if($exe_option_no  - 4194304 >= 0) {
			$tmp = join(",", "23", $tmp);
			$exe_option_no = $exe_option_no - 4194304;
		}
		if($exe_option_no  - 2097152 >= 0) {
			$tmp = join(",", "22", $tmp);
			$exe_option_no = $exe_option_no - 2097152;
		}
		if($exe_option_no  - 1048576 >= 0) {
			$tmp = join(",", "21", $tmp);
			$exe_option_no = $exe_option_no - 1048576;
		}
		if($exe_option_no  - 524288 >= 0) {
			$tmp = join(",", "20", $tmp);
			$exe_option_no = $exe_option_no - 524288;
		}
		if($exe_option_no  - 262144 >= 0) {
			$tmp = join(",", "19", $tmp);
			$exe_option_no = $exe_option_no - 262144;
		}
		if($exe_option_no  - 131072 >= 0) {
			$tmp = join(",", "18", $tmp);
			$exe_option_no = $exe_option_no - 131072;
		}
		if($exe_option_no  - 65536 >= 0) {
			$tmp = join(",", "17", $tmp);
			$exe_option_no = $exe_option_no - 65536;
		}
		if($exe_option_no  - 32768 >= 0) {
			$tmp = join(",", "16", $tmp);
			$exe_option_no = $exe_option_no - 32768;
		}
		if($exe_option_no  - 16384 >= 0) {
			$tmp = join(",", "15", $tmp);
			$exe_option_no = $exe_option_no - 16384;
		}
		if($exe_option_no  - 8192 >= 0) {
			$tmp = join(",", "14", $tmp);
			$exe_option_no = $exe_option_no - 8192;
		}
		if($exe_option_no  - 4096 >= 0) {
			$tmp = join(",", "13", $tmp);
			$exe_option_no = $exe_option_no - 4096;
		}
		if($exe_option_no  - 2048 >= 0) {
			$tmp = join(",", "12", $tmp);
			$exe_option_no = $exe_option_no - 2048;
		}
		if($exe_option_no  - 1024 >= 0) {
			$tmp = join(",", "11", $tmp);
			$exe_option_no = $exe_option_no - 1024;
		}
		if($exe_option_no  - 512 >= 0) {
			$tmp = join(",", "10", $tmp);
			$exe_option_no = $exe_option_no - 512;
		}
		if($exe_option_no  - 256 >= 0) {
			$tmp = join(",", "9", $tmp);
			$exe_option_no = $exe_option_no - 256;
		}
		if($exe_option_no  - 128 >= 0) {
			$tmp = join(",", "8", $tmp);
			$exe_option_no = $exe_option_no - 128;
		}
		if($exe_option_no  - 64 >= 0) {
			$tmp = join(",", "7", $tmp);
			$exe_option_no = $exe_option_no - 64;
		}
		if($exe_option_no  - 32 >= 0) {
			$tmp = join(",", "6", $tmp);
			$exe_option_no = $exe_option_no - 32;
		}
		if($exe_option_no  - 16 >= 0) {
			$tmp = join(",", "5", $tmp);
			$exe_option_no = $exe_option_no - 16;
		}
		if($exe_option_no  - 8 >= 0) {
			$tmp = join(",", "4", $tmp);
			$exe_option_no = $exe_option_no - 8;
		}
		if($exe_option_no  - 4 >= 0) {
			$tmp = join(",", "3", $tmp);
			$exe_option_no = $exe_option_no - 4;
		}
		if($exe_option_no  - 2 >= 0) {
			$tmp = join(",", "2", $tmp);
			$exe_option_no = $exe_option_no - 2;
		}
		if($exe_option_no  - 1 >= 0) {
			$tmp = join(",", "1", $tmp);
			$exe_option_no = $exe_option_no - 1;
		}
		if($exe_option_no > 0) {
			&logOutput("ERROR", "replaceEscalationMonthday", "オブジェクト名=$object_name, monthday=$monthday");
			$monthday = "Perlを見直してください"; 
			return($monthday); 
		}
		$tmp = substr($tmp, 0, length($tmp) - 1);
		$monthday = $tmp; 
	}
	return($monthday); 
}	

### escalation 曜日 コード変換用の関数 ###
sub replaceEscalationWeekday{
	$object_name = $_[0];	# オブジェクト名
	$weekday = $_[1];
	
	# escl-weekdayの置換
	if($weekday ne ""){ 
		$exe_option_no = $weekday;
		$tmp = "";
		if($exe_option_no  - 64 >= 0) {
			$tmp = join(",", "Saturday", $tmp);
			$exe_option_no = $exe_option_no - 64;
		}
		if($exe_option_no  - 32 >= 0) {
			$tmp = join(",", "Friday", $tmp);
			$exe_option_no = $exe_option_no - 32;
		}
		if($exe_option_no  - 16 >= 0) {
			$tmp = join(",", "Thursday", $tmp);
			$exe_option_no = $exe_option_no - 16;
		}
		if($exe_option_no  - 8 >= 0) {
			$tmp = join(",", "Wednesday", $tmp);
			$exe_option_no = $exe_option_no - 8;
		}
		if($exe_option_no  - 4 >= 0) {
			$tmp = join(",", "Tuesday", $tmp);
			$exe_option_no = $exe_option_no - 4;
		}
		if($exe_option_no  - 2 >= 0) {
			$tmp = join(",", "Monday", $tmp);
			$exe_option_no = $exe_option_no - 2;
		}
		if($exe_option_no  - 1 >= 0) {
			$tmp = join(",", "Sunday", $tmp);
			$exe_option_no = $exe_option_no - 1;
		}
		if($exe_option_no > 0) {
			&logOutput("ERROR", "replaceEscalationWeekday", "オブジェクト名=$object_name, weekday=$weekday");
			$weekday = "Perlを見直してください"; 
			return($weekday); 
		}
		$tmp = substr($tmp, 0, length($tmp) - 1);
		$weekday = $tmp;
	}
	return($weekday); 
}

### escalation 時間 コード変換用の関数 ###
sub replaceEscalationHourmask{
	$object_name = $_[0];	# オブジェクト名
	$hourmask = $_[1];
	
	if($hourmask ne ""){ 
		$exe_option_no = $hourmask;
		$tmp = "";
		if($exe_option_no  - 8388608 >= 0) {
			$tmp = join(",", "11PM", $tmp);
			$exe_option_no = $exe_option_no - 8388608;
		}
		if($exe_option_no  - 4194304 >= 0) {
			$tmp = join(",", "10PM", $tmp);
			$exe_option_no = $exe_option_no - 4194304;
		}
		if($exe_option_no  - 2097152 >= 0) {
			$tmp = join(",", "9PM", $tmp);
			$exe_option_no = $exe_option_no - 2097152;
		}
		if($exe_option_no  - 1048576 >= 0) {
			$tmp = join(",", "8PM", $tmp);
			$exe_option_no = $exe_option_no - 1048576;
		}
		if($exe_option_no  - 524288 >= 0) {
			$tmp = join(",", "7PM", $tmp);
			$exe_option_no = $exe_option_no - 524288;
		}
		if($exe_option_no  - 262144 >= 0) {
			$tmp = join(",", "6PM", $tmp);
			$exe_option_no = $exe_option_no - 262144;
		}
		if($exe_option_no  - 131072 >= 0) {
			$tmp = join(",", "5PM", $tmp);
			$exe_option_no = $exe_option_no - 131072;
		}
		if($exe_option_no  - 65536 >= 0) {
			$tmp = join(",", "4PM", $tmp);
			$exe_option_no = $exe_option_no - 65536;
		}
		if($exe_option_no  - 32768 >= 0) {
			$tmp = join(",", "3PM", $tmp);
			$exe_option_no = $exe_option_no - 32768;
		}
		if($exe_option_no  - 16384 >= 0) {
			$tmp = join(",", "2PM", $tmp);
			$exe_option_no = $exe_option_no - 16384;
		}
		if($exe_option_no  - 8192 >= 0) {
			$tmp = join(",", "1PM", $tmp);
			$exe_option_no = $exe_option_no - 8192;
		}
		if($exe_option_no  - 4096 >= 0) {
			$tmp = join(",", "12PM", $tmp);
			$exe_option_no = $exe_option_no - 4096;
		}
		if($exe_option_no  - 2048 >= 0) {
			$tmp = join(",", "11AM", $tmp);
			$exe_option_no = $exe_option_no - 2048;
		}
		if($exe_option_no  - 1024 >= 0) {
			$tmp = join(",", "10AM", $tmp);
			$exe_option_no = $exe_option_no - 1024;
		}
		if($exe_option_no  - 512 >= 0) {
			$tmp = join(",", "9AM", $tmp);
			$exe_option_no = $exe_option_no - 512;
		}
		if($exe_option_no  - 256 >= 0) {
			$tmp = join(",", "8AM", $tmp);
			$exe_option_no = $exe_option_no - 256;
		}
		if($exe_option_no  - 128 >= 0) {
			$tmp = join(",", "7AM", $tmp);
			$exe_option_no = $exe_option_no - 128;
		}
		if($exe_option_no  - 64 >= 0) {
			$tmp = join(",", "6AM", $tmp);
			$exe_option_no = $exe_option_no - 64;
		}
		if($exe_option_no  - 32 >= 0) {
			$tmp = join(",", "5AM", $tmp);
			$exe_option_no = $exe_option_no - 32;
		}
		if($exe_option_no  - 16 >= 0) {
			$tmp = join(",", "4AM", $tmp);
			$exe_option_no = $exe_option_no - 16;
		}
		if($exe_option_no  - 8 >= 0) {
			$tmp = join(",", "3AM", $tmp);
			$exe_option_no = $exe_option_no - 8;
		}
		if($exe_option_no  - 4 >= 0) {
			$tmp = join(",", "2AM", $tmp);
			$exe_option_no = $exe_option_no - 4;
		}
		if($exe_option_no  - 2 >= 0) {
			$tmp = join(",", "1AM", $tmp);
			$exe_option_no = $exe_option_no - 2;
		}
		if($exe_option_no  - 1 >= 0) {
			$tmp = join(",", "12AM", $tmp);
			$exe_option_no = $exe_option_no - 1;
		}
		if($exe_option_no > 0) {
			&logOutput("ERROR", "replaceEscalationHourmask", "オブジェクト名=$object_name, hourmask=$hourmask");
			$hourmask = "Perlを見直してください"; 
			return($hourmask); 
		}
		$tmp = substr($tmp, 0, length($tmp) - 1);
		$hourmask = $tmp; 
	}
	return($hourmask); 
}

### Container オブジェクト種類 コード変換用の関数 ###
sub replaceContainerType{
	$object_name = $_[0];	# オブジェクト名
	$type = $_[1];
	
	# typeの置換
	if($type eq 1){ $type="Active Link Guides"; }
	elsif($type eq 4){ $type="Filter Guides"; }
	elsif($type eq 5){ $type="Web Service"; }
	else{
		&logOutput("ERROR", "replaceContainerType", "オブジェクト名=$object_name, type=$type");
		$type = "Perlを見直してください"; 
	}
	return($type);
}

### Container Reference 参照オブジェクトタイプ コード変換用の関数 ###
sub replaceCtReferenceType{
	$object_name = $_[0];	# オブジェクト名
	$type = $_[1];

	# typeの置換
	if($type eq 3){ $type="Filter"; }
	elsif($type eq 5){ $type="Active Link"; }
	elsif($type eq 32774){ $type="Label"; }
	else{
		&logOutput("ERROR", "replaceCtReferenceType", "オブジェクト名=$object_name, type=$type");
		$type = "Perlを見直してください"; 
	}
	return($type);
}

### Container Reference 値 コード変換用の関数 ###
sub replaceCtReferenceValue{
	$object_name = $_[0];	# オブジェクト名
	$value = $_[1];

	# valueを\で分割
	$value =~ /\\/;
	
	# 値のみ取得
	$value = "$`";
	return($value);
}


################
# 整形系関数   #
################

### Action整形 ###
sub formatAction{
	# 引数の取得
	$object_name = $_[0];	# オブジェクト名
	$al_fl_flag = $_[1];	# ActiveLinkとFilterの識別	0:ActiveLink	1:Filter
	$if_else = $_[2];		# IfとElseの識別			0:If Action	1:Else Action
	$serial_no = $_[3];
	
	# [ActiveLink][Filter]以外はエラー
	if($al_fl_flag ne "ActiveLink" && $al_fl_flag ne "Filter" && $al_fl_flag ne "Escalation"){
		&logOutput("ERROR", "formatAction", "オブジェクト名=$object_name, al_fl_flag=$al_fl_flag");
	}
	
	# [0 If Action][1 Else Action]以外はエラー
	if($if_else ne "0 If Action" && $if_else ne "1 Else Action"){
		&logOutput("ERROR", "formatAction", "オブジェクト名=$object_name, if_else=$if_else");
	}
	
	# Action通番を3桁にする
	$serial_no = sprintf("%03d", $serial_no);
	
	@action_item = ();	# actionの項目
	$item_cnt = 1;		# 項目数
	$line = <IN>;
	# 閉じ括弧まで処理を続ける
	while($line !~ /^   \}/){
		if($line =~ /: /){
			# 項目と値の取得
			$item = "$`";
			$value = "$'";
			%split_data = ();
			@split_data = split(/\\/, $value);
			chomp($item);
			chomp($value);
			$item =~ s/^ *(.*?) *$/$1/;
			$value =~ s/[\r]/ /g;
			$value =~ s/[\n]//g;
			$value =~ s/\t/ /g;
			$value_head = $split_data[0];

			# すでにaction{}の中で項目を定義している場合
			if(defined($action_item[$item_cnt]{$item})){
				# 値の続きであるもの
				# (例)
				# open-input  : 7\536870913\102\1\@\1\@\1\536870996\0\1\4\536870982\102\1\@\1\@\1\536870983\0\1\4\536870930\101\6\0\536870922\102\1\@\1\@\1\536871261\0\1\4\536870977\10
				# open-input  : 2\1\@\1\@\1\536870977\0\1\4\536870978\102\1\@\1\@\1\536870932\0\1\4\536870932\101\6\0\
				# 
				if($item eq "open-input"
					|| $item eq "open-output"
					|| $item eq "open-rptstr"
					|| $item eq "message-text"
					|| $item eq "direct-sql"
					|| ($item eq "set-field" && $value_head eq $value_head_before)
					|| ($item eq "push-field" && $value_head eq $value_head_before)
					){
					#$action_item[$item_cnt]{$item} = $action_item[$item_cnt]{$item} . $value;
					if($item eq "set-field"){
						$value  =~ s/$value_head\\//;
					}
					elsif($item eq "push-field"){
						$value  =~ s/$value_head\\//;
					}
					$action_item[$item_cnt]{$item} = $action_item[$item_cnt]{$item} . $value;
				}
				# 同じ項目だが値(意味)が違うもの
				# (例)
				# set-field   : 0\536871019\102\1\@\21\CURE_TA_ContactPerson\1\536870955\4\1\1\536870929\99\536870998\2\3\
				# set-field   : 1\536871017\102\1\@\21\CURE_TA_ContactPerson\1\536870954\4\1\1\536870929\99\536870998\2\3\
				# set-field   : 2\536871014\102\1\@\21\CURE_TA_ContactPerson\1\536870984\4\1\1\536870929\99\536870998\2\3\
				# set-field   : 3\536871013\102\1\@\21\CURE_TA_ContactPerson\1\536870949\4\1\1\536870929\99\536870998\2\3\
				# ⇒1行目と2行目で先頭の数字が異なるため、別項目を設定していると分かる
				#
				else{
					$item_cnt++;
					$action_item[$item_cnt]{$item} = $value;
				}
			}
			# まだaction{}の中で項目定義されていないもの
			else{
				$action_item[$item_cnt]{$item} = $value;
			}
		}
		# 次の行へ
		$line = <IN>;
		$value_head_before = $value_head;
	}
	
	# actlink-queryの設定
	if($al_fl_flag eq "ActiveLink"){
		$al_item{'actlink-query'} = $work_actlink_query;
	}elsif($al_fl_flag eq "Filter"){
		$fl_item{'filter-query'} = $work_filter_query;
	}else{
		$es_item{'escl-query'} = $work_escl_query;
	}
	
	# action{}を出力
	for ($i = 1; $i <= $item_cnt; $i++) {
		for ($j = 1; $j < $schema_cnt; $j++) {
			$seq = sprintf("%03d", $i);
			# ActiveLink Actionの出力
			if($al_fl_flag eq "ActiveLink"){
				$al_action{$al_item{'name'} . "\t" . $schema_name[$j] . "\t" . $if_else . "\t" . $serial_no. "\t" . $seq}= &replaceCodeAction($al_item{'name'}, $schema_name[$j], $action_item, $i);
			# Filter Actionの出力
			}elsif($al_fl_flag eq "Filter"){
				$fl_action{$fl_item{'name'} . "\t" . $schema_name[$j] . "\t" . $if_else . "\t" . $serial_no. "\t" . $seq}= &replaceCodeAction($fl_item{'name'}, $schema_name[$j], $action_item, $i);
			# Escalation Actionの出力
			}else{
				$es_action{$es_item{'name'} . "\t" . $schema_name[$j] . "\t" . $if_else . "\t" . $serial_no. "\t" . $seq}= &replaceCodeAction($es_item{'name'}, $schema_name[$j], $action_item, $i);
			}
		}
	}

	return 0;
}


### Actionコード変換用の関数 ###
sub replaceCodeAction{
	my $object_name = $_[0]; 
	my $schema_name = $_[1]; 
	my $action_item = $_[2]; 
	my $i = $_[3]; 
	my $j = 0;

	# データの初期化
	%split_data = ();
	$tmp = "";					# 最終的な文字列
	$type = "";					# オブジェクトの種類
	$call_guide = "";
	$change_field_name = "";
	$change_field_access = "";
	$change_field_visibility = "";
	$change_field_label = "";
	$change_field_label_color = "";
	$change_field_refresh = "";
	$change_field_levels = "";
	$change_field_panel = "";
	$change_field_drag = "";
	$change_field_drop = "";
	$change_field_option = "";
	$change_field_menu = "";
	$change_field_focus = "";
	$close_window = "";
	$direct_sql = "";
	$exit_guide = "";
	$goto = "";
	$goto_guide = "";
	$message_type = "";
	$message_number = "";
	$message_prompt = "";
	$message_content = "";
	$open_window_type = "";
	$open_window_ds_type = "";
	$open_window_target = "";
	$open_window_source = "";
	$open_window_schema = "";
	$open_window_view = "";
	$open_window_button = "";
	$open_window_qual = "";
	$open_window_input = "";
	$open_window_output = "";
	$push_field_out_form = "";
	$push_field_out_field = "";
	$push_field_dest = "";
	$push_field_qual = "";
	$push_field_no_match = "";
	$push_field_any_match = "";
	$push_field_in_form = "";
	$push_field_in_field = "";
	$run_process = "";
	$set_field_out_form = "";
	$set_field_out_field = "";
	$set_field_dest = "";
	$set_field_qual = "";
	$set_field_no_match = "";
	$set_field_mul_match = "";
	$set_field_in_form = "";
	$set_field_in_field = "";
	
	# タイプを確定
	# commit_changesの場合
	if(defined($action_item[$i]{'commit_changes'})){
		$type = "commit-changes";
	}
	# Call Guideの場合
	elsif(defined($action_item[$i]{'call-server'})){ 
		$type = "Call Guide";
		$call_guide = $action_item[$i]{'call-guide'};
	}
	# Change Fieldの場合
	elsif(defined($action_item[$i]{'id'})){ 
		$type = "Change Field";
		$change_field_name = $field_dict{$schema_name}{$action_item[$i]{'id'}};
		
		# access-opt
		if(defined($action_item[$i]{'access-opt'})){
			# フィールド名を取得し、データタイプを取得する
			$dataType = $field_dict_type{$schema_name}{$action_item[$i]{'id'}};
			
			# データタイプごとに処理が異なる
			if($dataType eq ""){
				
			}elsif(   $dataType eq 31
				  || $dataType eq 32
				  || $dataType eq 33
				  || $dataType eq 35
				  || $dataType eq 36
				  || $dataType eq 37){
				# コードを変換する
				if($action_item[$i]{'access-opt'} eq 0){
					$change_field_access = "Unchanged";
				}elsif($action_item[$i]{'access-opt'} eq 2){
					$change_field_access = "Enable";
				}elsif($action_item[$i]{'access-opt'} eq 3){
					$change_field_access = "Disable";
				}else{
					&logOutput("ERROR", "replaceCodeAction access-opt", "オブジェクト名=$object_name, action_item[$i]{'access-opt'}=$action_item[$i]{'access-opt'}");
					$change_field_access = "Perlを見直してください"; 
				}
			}elsif(   $dataType eq 2
				  || $dataType eq 4
				  || $dataType eq 6
				  || $dataType eq 7
				  || $dataType eq 10
				  || $dataType eq 13
				  || $dataType eq 14
				  ){
				# コードを変換する
				if($action_item[$i]{'access-opt'} eq 0){
					$change_field_access = "Unchanged";
				}elsif($action_item[$i]{'access-opt'} eq 1){
					$change_field_access = "Read Only";
				}elsif($action_item[$i]{'access-opt'} eq 2){
					$change_field_access = "Read/Write";
				}elsif($action_item[$i]{'access-opt'} eq 3){
					$change_field_access = "Disable";
				}else{
					&logOutput("ERROR", "replaceCodeAction access-opt", "オブジェクト名=$object_name, action_item[$i]{'access-opt'}=$action_item[$i]{'access-opt'}");
					$change_field_access = "Perlを見直してください"; 
				}
			}
			else{
				&logOutput("ERROR", "replaceCodeAction access-opt", "オブジェクト名=$object_name, dataType=$dataType");
				$change_field_access = "Perlを見直してください"; 
			}
		}
		
		# display-prop
		if(defined($action_item[$i]{'display-prop'})){
			$yen_str = $action_item[$i]{'display-prop'};
			$cnt = 0;
			$change_type = "";
			$item = "";
			# 変更箇所の個数を取得
			&splitYen($yen_str, $cnt);
			
			# 変更分ループ
			for ($j = 1; $j <= $cnt; $j++) {
				# 種別を取得
				&splitYen($yen_str, $change_type);
				# 何かしらの固定文字を削除
				&splitYen($yen_str, $item);
				
				# Field Visibilityの場合
				if($change_type eq 4){
					&splitYen($yen_str, $item);
					if($item eq 0){
						$change_field_visibility = "Hidden"
					}elsif($item eq 1){
						$change_field_visibility = "Visible"
					}else{
						&logOutput("ERROR", "replaceCodeAction Change Field Visibility", "オブジェクト名=$object_name, item=$item");
						$change_field_visibility = "Perlを見直してください"; 
					}
				# Field Labelの場合
				}elsif($change_type eq 20){
					# バイト数を取得
					&splitYen($yen_str, $item);
					# バイト数で文字列を取得
					&getStringByByte($object_name, $change_field_label, $yen_str, $item);
					$yen_str =  substr($yen_str, 1);
					
					# フィールドIDの場合は置換
					if($change_field_label =~ /^\$[0-9]+\$/){
						$change_field_label = substr($change_field_label, 1, length($change_field_label)-2);
						$change_field_label = "\$" . $field_dict{$schema_name}{$change_field_label} . "\$";
					}
				# Label Colorの場合
				}elsif($change_type eq 24){
					# バイト数を取得
					&splitYen($yen_str, $item);
					if($item eq 0){
						&splitYen($yen_str, $item);
						$change_field_label_color = "Default";
					}else{
						&splitYen($yen_str, $item);
						$change_field_label_color = $item;
					}
				# Refresh Tree/Tableの場合
				}elsif($change_type eq 225){
					# 値を取得
					&splitYen($yen_str, $item);
					if($item eq 0){
						$change_field_refresh = "";
					}elsif($item eq 1){
						$change_field_refresh = "Refresh Tree/Table";
					}else{
						&logOutput("ERROR", "replaceCodeAction Change Field refresh", "オブジェクト名=$object_name, item=$item");
						$change_field_refresh = "Perlを見直してください"; 
					}
				# Expand Collapse Tree Levelsの場合
				}elsif($change_type eq 270){
					# 値を取得
					&splitYen($yen_str, $item);
					if($item eq 1){
						$change_field_levels = "Expand All Levels";
					}elsif($item eq 2){
						$change_field_levels = "Collapse All Levels";
					}else{
						&logOutput("ERROR", "replaceCodeAction Change Field level", "オブジェクト名=$object_name, item=$item");
						$change_field_levels = "Perlを見直してください"; 
					}
				# Expand Collapse Panelの場合
				}elsif($change_type eq 286){
					# 値を取得
					&splitYen($yen_str, $item);
					if($item eq 0){
						$change_field_panel = "Collapse";
					}elsif($item eq 1){
						$change_field_panel = "Expand";
					}else{
						&logOutput("ERROR", "replaceCodeAction Change Field panel", "オブジェクト名=$object_name, item=$item");
						$change_field_panel = "Perlを見直してください"; 
					}
				# Field Dragの場合
				}elsif($change_type eq 314){
					# 値を取得
					&splitYen($yen_str, $item);
					if($item eq 0){
						$change_field_drag = "Disable";
					}elsif($item eq 1){
						$change_field_drag = "Enable";
					}else{
						&logOutput("ERROR", "replaceCodeAction Change Field drag", "オブジェクト名=$object_name, item=$item");
						$change_field_drag = "Perlを見直してください"; 
					}
				# Field Dropの場合
				}elsif($change_type eq 315){
					# 値を取得
					&splitYen($yen_str, $item);
					if($item eq 0){
						$change_field_drop = "Disable";
					}elsif($item eq 1){
						$change_field_drop = "Enable";
					}else{
						&logOutput("ERROR", "replaceCodeAction Change Field drop", "オブジェクト名=$object_name, item=$item");
						$change_field_drop = "Perlを見直してください"; 
					}
				# それ以外の場合
				}else{
					&logOutput("ERROR", "replaceCodeAction Change Field display-prop", "オブジェクト名=$object_name, change_type=$change_type");
					$change_field_visibility = "Perlを見直してください"; 
				}
			}
		}
		
		# option
		if(defined($action_item[$i]{'option'})){
			$change_field_option = $action_item[$i]{'option'};
		}
		
		# char-menu
		if(defined($action_item[$i]{'char-menu'})){
			$change_field_menu = $action_item[$i]{'char-menu'};
		}
		
		# focus
		if(defined($action_item[$i]{'focus'})){
			if($action_item[$i]{'focus'} eq 0){
				# 0の場合はチェックなし
				$change_field_focus = "";
			}elsif($action_item[$i]{'focus'} eq 1){
				# 1の場合はチェックあり
				$change_field_focus = "Set Focus to Field";
			}else{
				&logOutput("ERROR", "replaceCodeAction change field focus", "オブジェクト名=$object_name, action_item[$i]{'focus'}=$action_item[$i]{'focus'}");
				$change_field_focus = "Perlを見直してください"; 
			}
		}
	}
	# Close Windowの場合
	elsif(defined($action_item[$i]{'close-wnd'})){
		$type = "Close Window";
		
		if($action_item[$i]{'close-all'} eq 0){
			$close_window = "Close Current";
		}elsif($action_item[$i]{'close-all'} eq 1){
			$close_window = "Close All";
		}else{
			&logOutput("ERROR", "replaceCodeAction close window close-all", "オブジェクト名=$object_name, action_item[$i]{'close-all'}=$action_item[$i]{'close-all'}");
			$close_window = "Perlを見直してください"; 
		}
		
	}
	# Direct SQLの場合
	elsif(defined($action_item[$i]{'direct-sql'})){
		$item = "";
		$type = "Direct SQL";
		$qual = $action_item[$i]{'direct-sql'};
		
		# 1\を取得
		&splitYen($qual, $item);
		# @\を取得
		&splitYen($qual, $item);
		# バイト数を取得
		&splitYen($qual, $item);
		
		# バイト数で文字列を取得
		&getStringByByte($object_name, $direct_sql, $qual, $item);
	}
	# Exit Guideの場合
	elsif(defined($action_item[$i]{'exit guide'})){ 
		$type = "exit guide";
		
		if($action_item[$i]{'exit guide'} eq 0){
			$exit_guide = "-";
		}elsif($action_item[$i]{'exit guide'} eq 1){
			$exit_guide = "Close All Guides on Exit";
		}else{
			&logOutput("ERROR", "replaceCodeAction exit guide", "オブジェクト名=$object_name, action_item[$i]{'exit guide'}=$action_item[$i]{'exit guide'}");
			$exit_guide = "Perlを見直してください"; 
		}
	}
	# gotoの場合
	elsif(defined($action_item[$i]{'goto action'})){
		$type = "goto action";
		
		@split_data = split(/\\/, $action_item[$i]{'goto action'});
		if($split_data[0] eq 2){
			$goto = $split_data[1];
		}else{
			&logOutput("ERROR", "replaceCodeAction goto action", "オブジェクト名=$object_name, action_item[$i]{'goto action'}=$action_item[$i]{'goto action'}");
			$goto = "Perlを見直してください"; 
		}
		
	}
	# goto guideの場合
	elsif(defined($action_item[$i]{'goto guide'})){
		$type = "goto guide";
		$goto_guide = $action_item[$i]{'goto guide'};
	}
	# Messageの場合
	elsif(defined($action_item[$i]{'message-type'})){
		$type = "Message";
		
		# message-type
		if($action_item[$i]{'message-type'} eq 0){
			$message_type = "Note";
		}elsif($action_item[$i]{'message-type'} eq 1){
			$message_type = "Warning";
		}elsif($action_item[$i]{'message-type'} eq 2){
			$message_type = "Error";
		}elsif($action_item[$i]{'message-type'} eq 3){
			$message_type = "Prompt";
		}elsif($action_item[$i]{'message-type'} eq 4){
			$message_type = "Accessible";
		}elsif($action_item[$i]{'message-type'} eq 5){
			$message_type = "Tooltip";
		}else{
			&logOutput("ERROR", "replaceCodeAction Message message-type", "オブジェクト名=$object_name, action_item[$i]{'message-type'}=$action_item[$i]{'message-type'}");
			$message_type = "Perlを見直してください"; 
		}
		
		if(defined($action_item[$i]{'message-pane'})){
			if($action_item[$i]{'message-pane'} eq 0){
				$message_prompt = "-";
			}elsif($action_item[$i]{'message-pane'} eq 1){
				$message_prompt = "Show Message in Prompt Bar";
			}
			else{
				&logOutput("ERROR", "replaceCodeAction Message message-pane", "オブジェクト名=$object_name, action_item[$i]{'message-pane'}=$action_item[$i]{'message-pane'}");
				$message_prompt = "Perlを見直してください"; 
			}
		}
		
		# number
		$message_number = $action_item[$i]{'message-num'};
		
		# content
		$message_content = $action_item[$i]{'message-text'};
		# フィールドIDの場合は置換
		while($message_content =~ /\$[0-9]+\$/){
			$match = "$&";
			$field_id = substr($match, 1, length($match)-2);
			$message_content =~ s/$field_id/$field_dict{$schema_name}{$field_id}/;
		}
	}
	# Open Windowの場合
	elsif(defined($action_item[$i]{'open-server'})){
		$type = "Open Window";
		
		# open-winmod
		if($action_item[$i]{'open-winmod'} eq 0){
			$open_window_type = "Dialog";
		}elsif($action_item[$i]{'open-winmod'} eq 1){
			$open_window_type = "Search";
		}elsif($action_item[$i]{'open-winmod'} eq 2){
			$open_window_type = "Submit";
		}elsif($action_item[$i]{'open-winmod'} eq 4){
			$open_window_type = "Modify";
			$open_window_ds_type = "Detail Only";
		}elsif($action_item[$i]{'open-winmod'} eq 5){
			$open_window_type = "Modify";
			$open_window_ds_type = "Split Window";
		}elsif($action_item[$i]{'open-winmod'} eq 7){
			$open_window_type = "Display";
			$open_window_ds_type = "Detail Only";
		}elsif($action_item[$i]{'open-winmod'} eq 9){
			$open_window_type = "Report";
		}elsif($action_item[$i]{'open-winmod'} eq 10){
			$open_window_type = "Modify";
			$open_window_ds_type = "Clear";
		}elsif($action_item[$i]{'open-winmod'} eq 11){
			$open_window_type = "Display";
			$open_window_ds_type = "Clear";
		}elsif($action_item[$i]{'open-winmod'} eq 14){
			$open_window_type = "Modify Directly";
			$open_window_ds_type = "Detail Only";
		}elsif($action_item[$i]{'open-winmod'} eq 20){
			$open_window_type = "Popup";
		}else{
			&logOutput("ERROR", "replaceCodeAction Open Window type", "オブジェクト名=$object_name, action_item[$i]{'open-winmod'}=$action_item[$i]{'open-winmod'}");
			$open_window_type = "Perlを見直してください"; 
		}
		
		# open-target
		$open_window_target  = $action_item[$i]{'open-target'};
		
		# open-server
		if($action_item[$i]{'open-server'} eq "@"){
			$open_window_source = "SERVER";
		}elsif($action_item[$i]{'open-server'} eq "\$-6\$"){
			$open_window_source = "SAMPLE DATA";
		}else{
			&logOutput("ERROR", "replaceCodeAction Open Window server", "オブジェクト名=$object_name, action_item[$i]{'open-server'}=$action_item[$i]{'open-server'}");
			$open_window_source = "Perlを見直してください"; 
		}
		
		# open-schema
		$open_window_schema = $action_item[$i]{'open-schema'};
		
		# open-vui
		$open_window_view = $action_item[$i]{'open-vui'};
		
		# open_window_button
		if($action_item[$i]{'open_window_button'} eq "1"){
			$open_window_button = "Show Close Button";
		}else{
			$open_window_button = "-";
		}

		# open-query ※整形は出力時に実施
		if(defined($action_item[$i]{'open-query'})){ 
			#$open_window_qual = &formatQualification($action_item[$i]{'open-query'}, $object_name, $schema_name, $open_window_schema);
			$open_window_qual = $action_item[$i]{'open-query'};
		}

		# open-input ※整形は出力時に実施
		if($action_item[$i]{'open-input'} eq "0\\"){
			$open_window_input = "-";
		}else{
			$open_window_input = $action_item[$i]{'open-input'};
		}
		
		# open-output ※整形は出力時に実施
		if($action_item[$i]{'open-output'} eq "0\\"){
			$open_window_output = "-";
		}else{
			$open_window_output = $action_item[$i]{'open-output'};
		}
		

#					, $action_item[$i]{'open-server'}
#					, $action_item[$i]{'open-schema'}
#					, $action_item[$i]{'open-vui'}
#					, $action_item[$i]{'open-close'}
#					, $action_item[$i]{'open-query'}
#					, $action_item[$i]{'open-input'}
#					, $action_item[$i]{'open-output'}
#					, $action_item[$i]{'open-winmod'}
#					, $action_item[$i]{'open-target'}
#					, $action_item[$i]{'open-pollint'}
#					, $action_item[$i]{'open-continu'}
#					, $action_item[$i]{'open-suppres'}
#					, $action_item[$i]{'open-msgtype'}
#					, $action_item[$i]{'open-msgnum'}
#					, $action_item[$i]{'open-msgpane'}
#					);
	}
	# push-fieldの場合 ※整形は出力時に実施
	elsif(defined($action_item[$i]{'push-field'})){
		$type = "push-field";
		
		$push_field_out_form = $action_item[$i]{'push-field'};
		$push_field_out_field = "";
		$push_field_dest      = "";
		$push_field_qual      = "";
		$push_field_no_match  = "";
		$push_field_any_match = "";
		$push_field_in_form   = "";
		$push_field_in_field  = "";
	}
	# Run Processの場合
	elsif(defined($action_item[$i]{'command'})){ 
		$type = "Run Process";
		$run_process = $action_item[$i]{'command'};
	}
	# set-fieldの場合 ※整形は出力時に実施
	elsif(defined($action_item[$i]{'set-field'})){ 
		$type = "set-field";
		
		$set_field_out_form  = $action_item[$i]{'set-field'};
		$set_field_out_field = "";
		$set_field_dest      = "";
		$set_field_qual      = "";
		$set_field_no_match  = "";
		$set_field_mul_match = "";
		$set_field_in_form   = "";
		$set_field_in_field  = "";
	}
	else{
	}
	
	$tmp = join("\t"
				, $type
				, $call_guide
				, $change_field_name
				, $change_field_access
				, $change_field_visibility
				, $change_field_label
				, $change_field_label_color
				, $change_field_refresh
				, $change_field_levels
				, $change_field_panel
				, $change_field_drag
				, $change_field_drop
				, $change_field_option
				, $change_field_menu
				, $change_field_focus
				, $close_window
				, $direct_sql
				, $exit_guide
				, $goto
				, $goto_guide
				, $message_type
				, $message_number
				, $message_prompt
				, $message_content
				, $open_window_type
				, $open_window_ds_type
				, $open_window_target
				, $open_window_source
				, $open_window_schema
				, $open_window_view
				, $open_window_button
				, $open_window_qual
				, $open_window_input
				, $open_window_output
				, $push_field_out_form
				, $push_field_out_field
				, $push_field_dest
				, $push_field_qual
				, $push_field_no_match
				, $push_field_any_match
				, $push_field_in_form
				, $push_field_in_field
				, $run_process
				, $set_field_out_form
				, $set_field_out_field
				, $set_field_dest
				, $set_field_qual
				, $set_field_no_match
				, $set_field_mul_match
				, $set_field_in_form
				, $set_field_in_field
				);
	return($tmp);
}

###############################
# Qualificationの設定
###############################
sub formatQualification{
	my $qual = $_[0];			# 対象とする文字列
	my $object_name = $_[1];	# オブジェクト名
	my $schema_name = $_[2];	# オブジェクトのスキーマ
	my $server_name = $_[3];	# SERVERのスキーマ
	my $hanten_flag = $_[4];	# 0:push-field(1がオブジェクトで99がSERVER) 1:set-field(1がSERVERで99がオブジェクト) ？要確認
	
    my $item_nec_cnt = 1;		# ループ制御用
    my $item_nec_cnt2 = 0;		# ループ制御用
    my $work_swap = "";			# スワップ用
    my $quote_str = "'";		# シングルクォート文字
	my $i = 0;
	my $j = 0;
	my %data = ();
	
	# 反転フラグが立っている場合、スワップ
	if($hanten_flag eq 1){
		 $work_swap = $schema_name;
		 $schema_name = $server_name;
		 $server_name = $work_swap;
	}
	
	while($item_nec_cnt > 0){
		# 演算文字を取得
		&splitYen($qual, $item);
		
		# 0の場合終了
		if($item eq 0){
			$qual = "";
			return 0;
		# ANDの場合
		}elsif($item eq 1){
			$data[$i] = "AND";
			$i++;
			$item_nec_cnt++;
			
		# ORの場合
		}elsif($item eq 2){
			$data[$i] = "OR";
			$i++;
			$item_nec_cnt++;
			
		# NOTの場合
		}elsif($item eq 3){
			$data[$i] = "NOT";
			$i++;
			
		# 大小演算子の場合
		}elsif($item eq 4){
			# 演算子を取得
			&splitYen($qual, $item);
			$data[$i] = &replaceOperator($item);
			$i++;
			$item_nec_cnt2 = 2;
			
			while($item_nec_cnt2 > 0){
				# 種類を取得
				&splitYen($qual, $item);
				
				# 1の場合、フィールド
				if($item eq 1){
					&splitYen($qual, $item);
					if($hanten_flag eq 1){
						$data[$i] = "\'" . &replaceIdtoName($object_name, $schema_name, $item) . "\'";
					}else{
						$data[$i] = "\$" . &replaceIdtoName($object_name, $schema_name, $item) . "\$";
					}
					$i++;
					$item_nec_cnt2--;
				# 2の場合、固定値
				}elsif($item eq 2){
					# 種類を取得
					&splitYen($qual, $item);
					
					# 0の場合、$NULL$
					if($item eq 0){
						$data[$i] = "\$NULL\$";
					# 1の場合、keyword
					}elsif($item eq 1){
						&splitYen($qual, $item);
						$data[$i] = &replaceKeyword($item);
					# 2の場合、整数
					}elsif($item eq 2){
						&splitYen($qual, $item);
						$data[$i] = $item;
					# 4の場合、文字列
					}elsif($item eq 4){
						&splitYen($qual, $item);
						$work_str = "";
						# バイト数で文字列を取得
						&getStringByByte($object_name, $work_str, $qual, $item);
						$qual =  substr($qual, 1);
						
						$data[$i] = "\"" . $work_str . "\"";
					# 6の場合、Selection Data⇒Selection Dataは式の右側しかこない
					}elsif($item eq 6){
						&splitYen($qual, $item);
						$work_str = $data[$i-1];
						$work_str =~ s/TR\.//g;
						$work_str =~ s/DB\.//g;
						$work_str =~ s/\$//g;
						$work_str =~ s/$quote_str//g;
						$work_str = &replaceNametoId($object_name, $schema_name, $work_str);
						$data[$i] = "\"" . &replaceSelectionData($object_name, $schema_name, $work_str, $item) . "\"";
					# 7の場合、日付
					}elsif($item eq 7){
						# 日付を取得
						&splitYen($qual, $item);
						$data[$i] = &replaceTimestamp("Qualification", $item);
					# 10の場合、小数
					}elsif($item eq 10){
						# バイトを取得
						&splitYen($qual, $item);
						$data[$i] = substr($qual, 0, $item);
						$qual = substr($qual, $item+1);
					}else{
						return $qual;
					}
					$i++;
					$item_nec_cnt2--;
					
				# 3の場合、四則演算
				}elsif($item eq 3){
					# 四則演算を取得
					&splitYen($qual, $item);
					$data[$i] = &replaceOperator($item);
					$i++;
					$item_nec_cnt2++;
				# 50の場合、フィールド(TR:トランザクション)
				}elsif($item eq 50){
					# フィールドを取得
					&splitYen($qual, $item);
					$data[$i] = "TR." . &replaceIdtoName($object_name, $schema_name, $item);
					$i++;
					$item_nec_cnt2--;
				# 51の場合、フィールド(DB:データベース)
				}elsif($item eq 51){
					# フィールドを取得
					&splitYen($qual, $item);
					$data[$i] = "DB." . &replaceIdtoName($object_name, $schema_name, $item);
					$i++;
					$item_nec_cnt2--;
				# 99の場合、フィールド
				}elsif($item eq 99){
					# フィールドを取得
					&splitYen($qual, $item);
					if($hanten_flag eq 1){
						$data[$i] = "\$" . &replaceIdtoName($object_name, $server_name, $item) . "\$";
					}else{
						$data[$i] = "\'" . &replaceIdtoName($object_name, $server_name, $item) . "\'";
					}
					$i++;
					$item_nec_cnt2--;
				}else{
					return $qual;
				}
			}
			$item_nec_cnt--;
			
		# EXTERNALの場合
		}elsif($item eq 5){
			# フィールドを取得
			&splitYen($qual, $item);
			if(defined($field_dict{$schema_name}{$item})){
				$data[$i] = "EXTERNAL\(\$" . $field_dict{$schema_name}{$item} . "\$\)";
			}else{
				$data[$i] = "EXTERNAL\(\$" . $item . "\$\)";
			}
			$i++;
			$item_nec_cnt = $item_nec_cnt - 1;
		}else{
			return $qual;
		}
	}

	# 式の組み立て
	for ($j = @data-1; $j >= 0; $j--) {
		# 演算子の場合
		if(    $data[$j] eq "="
			|| $data[$j] eq ">"
			|| $data[$j] eq "<"
			|| $data[$j] eq ">="
			|| $data[$j] eq "<="
			|| $data[$j] eq "!="
			|| $data[$j] eq "LIKE"
			|| $data[$j] eq "calc +"
			|| $data[$j] eq "calc -"
			|| $data[$j] eq "calc /"
			|| $data[$j] eq "calc *"){
			
			# calc があれば削除
			if($data[$j] =~ /calc /){
				$data[$j] = "$`" . "$'";
			}
			$data[$j] = "\(" . $data[$j+1] . " " . $data[$j] . " " . $data[$j+2] . "\)";
			# $j+1と$j+2を$jに取り込んだので、$j+1と$j+2を配列から削除
			splice(@data, $j+1, 2);
			$before_ope = "";
			
		}elsif($data[$j] eq "OR"){
			# 前回処理もORの場合、括弧を削除する
			if($before_ope eq "OR"){
				$data[$j] = "\(" . substr($data[$j+1], 1, length($data[$j+1])-1) . " OR " . $data[$j+2] . "\)";
			}else{
				$data[$j] = "\(" . $data[$j+1] . " OR " . $data[$j+2] . "\)";
			}
			# $j+1と$j+2を$jに取り込んだので、$j+1と$j+2を配列から削除
			splice(@data, $j+1, 2);
			$before_ope = "OR";
			
		}elsif($data[$j] eq "AND"){
			# 前回処理もANDの場合、括弧を削除する
			if($before_ope eq "AND"){
				$data[$j] = "\(" . substr($data[$j+1], 1, length($data[$j+1])-1) . " AND " . $data[$j+2] . "\)";
			}else{
				$data[$j] = "\(" . $data[$j+1] . " AND " . $data[$j+2] . "\)";
			}
			# $j+1と$j+2を$jに取り込んだので、$j+1と$j+2を配列から削除
			splice(@data, $j+1, 2);
			$before_ope = "AND";
			
		}elsif($data[$j] eq "NOT"){
            $data[$j] = "\( NOT\(" . substr($data[$j+1], 1, length($data[$j+1])-1) . "\)\)";
			splice(@data, $j+1, 1);
			$before_ope = "AND";
		}else{
			$before_ope = "";
		}
	}
	# 最後の両括弧は削除する
	if(   substr($data[0], 0, 1) eq "\("
	   && substr($data[0], length($data[0])-1) eq "\)"
	   ){
        $data[0] = substr($data[0], 1, length($data[0])-2);
    }
    $_[0] = $qual;
    $qual = $data[0];
	return $qual;
}

###############################
# open-input,open-outputの設定
###############################
sub formatOpenData{
	# 文字列を取得
	$set_data{'str'} = $set_data{'sentence'};
	
	#my $open_value = "\"";	# 最終的に設定したい文字列
	my $open_value = "";	# 最終的に設定したい文字列
	my $item_cnt = 0;
	my $set_field = "";
	my $i = 0;
	
	# 変更箇所の個数を取得
	&splitYen($set_data{'str'}, $item_cnt);
	$set_data{'out_form'} = $set_data{'server_name'};
	
	# 変更箇所分ループ
	for ($i = 1; $i <= $item_cnt; $i++) {
		# 項目を取得
		&splitYen($set_data{'str'}, $set_data{'out_field_id'});
		
		# フィールドIDの置換
		# Inputの場合
		if($set_data{'open_inout'} eq "OpenInput"){
			# Set Fields to Defaultsの場合
			if($i eq 1 && @set_data{'out_field_id'} eq 97){
				return "Set Fields to Defaults";
			}
			$set_data{'out_field'} = &replaceIdtoName($set_data{'object_name'}, $set_data{'server_name'}, @set_data{'out_field_id'});
		}
		# Outputの場合
		elsif($set_data{'open_inout'} eq "OpenOutput"){
			$set_data{'out_field'} = &replaceIdtoName($set_data{'object_name'}, $set_data{'schema_name'}, @set_data{'out_field_id'});
		}
		# それ以外はエラー
		else{
			&logOutput("ERROR", "formatOpenData", "Input Output識別エラー オブジェクト名=$set_data{'object_name'},処理中文字列=$set_data{'str'},元の文字列=$set_data{'sentence'}");
			return 0;
		}
		
		# 設定値を取得
		&formatSetFieldValue(@set_data);
		#$open_value = $open_value . $set_field . " | " . $set_data{'in_field'} . "\x0a";
		
		# 設定値を連結
		$open_value = $open_value . $set_data{'out_field'} . " | " . $set_data{'in_field'} . " ";
	}
	
	#$open_value = $open_value . "\"";
	
	return $open_value;
}

###############################
# push-fieldの整形
###############################
sub formatPushField{
	my $no_match = "";
	my $any_match = "";
	
	# 文字列を取得
	$set_data{'str'} = $set_data{'sentence'};
	
	# 項番を取得
	&splitYen($set_data{'str'}, $item);

	# 1を取得
	&splitYen($set_data{'str'}, $item);
	
	# @を取得
	&splitYen($set_data{'str'}, $item);
	
	# バイト数を取得
	&splitYen($set_data{'str'}, $item);
	
	# 設定先フォームを取得
	$set_data{'out_form'} = substr($set_data{'str'}, 0, $item);
	$set_data{'str'} =  substr($set_data{'str'}, $item+1);
	
	# 1を取得
	&splitYen($set_data{'str'}, $item);
	
	# 設定先の値を取得
	&splitYen($set_data{'str'}, $item);
	if($item eq 98){
		@set_data{'out_field'} = "Matching Ids";
	}else{
		@set_data{'out_field_id'} = $item;
		@set_data{'out_field'} = &replaceIdtoName($set_data{'object_name'}, $set_data{'out_form'}, @set_data{'out_field_id'});
	}
	
	# Qualificationを取得
	if(substr($set_data{'str'}, 0, 1) eq 0){
		# 0の場合は条件なし
		&splitYen($set_data{'str'}, $item);
	}else{
		$set_data{'qual'} = &formatQualification($set_data{'str'}, $set_data{'object_name'}, $set_data{'schema_name'}, $set_data{'out_form'}, 1);
	}
	
	# If No Requests Matchを取得
	&splitYen($set_data{'str'}, $item);
	$no_match = &replaceIfNoReqMatch($item);
	
	# If Any Requests Matchを取得
	&splitYen($set_data{'str'}, $item);
	$any_match = &replaceIfAnyReqMatch($item);

	# 設定元フォームを取得
	$set_data{'in_form'} = $set_data{'schema_name'};
	
	# 設定元の値を取得
	&formatSetFieldValue(@set_data);
	
	# Data Sourceを取得 ※簡易的に一律SERVER
	$set_data{'dest'} = "SERVER";
	
	# formatSetFieldValueの中で上書きされる可能性があるため、最後に書き込む
	$set_data{'no_match'} = $no_match;
	$set_data{'any_match'} = $any_match;
	
	return 0;
}

###############################
# set-fieldの整形
###############################
sub formatSetField{
	# 文字列を取得
	$set_data{'str'} = $set_data{'sentence'};
	
	# 項番を取得
	&splitYen($set_data{'str'}, $item);
	
	# フォーム名はオブジェクトのスキーマ
	$set_data{'out_form'} = $set_data{'schema_name'};
	
	# フィールドIDを取得
	&splitYen($set_data{'str'}, $item);
	$set_data{'out_field_id'} = $item;

	# Data Source～設定値を取得
	&formatSetFieldValue(@set_data);
	
	# フィールドIDを置換
	$set_data{'out_field'} = &replaceIdtoName($set_data{'object_name'}, $set_data{'schema_name'}, $set_data{'out_field_id'});
	
	return 0;
}

###############################
# 設定値の整形
###############################
sub formatSetFieldValue{
	my @in_field = ();			# 項目の個々
	my $field = "";				# 項目組み立て後の値
	my $sql_qual = "";			# sql文
	my $func_type = "";			# 105系 引数の種類
	my $func_str = "";			# 関数展開後の文字列
	my $i = 0;
	my $j = 0;
	my $k = 0;
	
	$loop_cnt = 1;				# 必要な項目数(最初は1) サブ関数でカウントアップするため、myはつけない
	
	# デフォルトのデータソース設定
	# ActiveLinkの場合
	if($set_data{'alfl'} eq 'ActiveLink'){
		$set_data{'dest'} = "CURRENT SCREEN";
	}
	# Filterの場合
	else{
		$set_data{'dest'} = "CURRENT TRUNSACTION";
	}
	
	# $loop_cntが0になるまで続ける
	while($loop_cnt ne 0){
		&splitYen($set_data{'str'}, $item);
		## 101系 固定値の設定 ##
		if($item eq 101){
			&splitYen($set_data{'str'}, $item);
			# NULLの場合
			if($item eq 0){
				$in_field[$i] = "\$NULL\$";
				
			# keywordの場合
			}elsif($item eq 1){
				&splitYen($set_data{'str'}, $item);
				$in_field[$i] = &replaceKeyword($item);
				
			# 整数の場合
			}elsif($item eq 2){
				&splitYen($set_data{'str'}, $item);
				$in_field[$i] = $item;
			
			# 文字列の場合
			}elsif($item eq 4){
				&splitYen($set_data{'str'}, $item);
				# バイト数で文字列を取得
				&getStringByByte($object_name, $in_field[$i], $set_data{'str'}, $item);
				$in_field[$i] = "\"" . $in_field[$i] . "\"";
				$set_data{'str'} =  substr($set_data{'str'}, 1);
				
			# Selectionデータの場合
			}elsif($item eq 6){
				&splitYen($set_data{'str'}, $item);
				#$in_field[$i] = $item;
				if($set_data{'push_set'} eq "Push" || $set_data{'open_inout'} eq "OpenInput"){
					$in_field[$i] = &replaceSelectionData($set_data{'object_name'}, $set_data{'out_form'}, $set_data{'out_field_id'}, $item);
				}else{
					$in_field[$i] = &replaceSelectionData($set_data{'object_name'}, $set_data{'schema_name'}, $set_data{'out_field_id'}, $item);
				}
				
			# 日付データの場合
			}elsif($item eq 7){
				&splitYen($set_data{'str'}, $item);
				$in_field[$i] = &replaceTimestamp($set_data{'object_name'}, $item);
				
			# 小数の場合
			}elsif($item eq 10){
				&splitYen($set_data{'str'}, $item);
				$in_field[$i] = substr($set_data{'str'}, 0, $item);
				$set_data{'str'} =  substr($set_data{'str'}, $item+1);
				
			# 時刻の場合
			}elsif($item eq 14){
				&splitYen($set_data{'str'}, $item);
				$in_field[$i] = &replaceTimestamp($set_data{'object_name'}, $item-32400);
				
			}else{
				# エラー
				&logOutput("ERROR", "replaceCodeAction", "101系エラー オブジェクト名=$set_data{'object_name'},処理中文字列=$set_data{'str'},元の文字列=$set_data{'sentence'}");
				return 0;
			}
			# 必要項目数を減らす
			$loop_cnt--;
			
		}
		## 102系 他フォームからの設定 ##
		elsif($item eq 102){
			# 1\@\ or 1\*\を削除
			&splitYen($set_data{'str'}, $item);
			&splitYen($set_data{'str'}, $item);
			
			if($item eq "\@"){
				# データソース設定
				$set_data{'dest'} = "SERVER";
				
				# バイト数を取得
				&splitYen($set_data{'str'}, $item);
				# フォームを取得
				if(substr($set_data{'str'}, 0, $item) eq "\@"){
					# open-outputの場合は、サーバー側を設定
					if($set_data{'open_inout'} eq "OpenOutput"){
						$set_data{'in_form'} = $set_data{'server_name'};
					}else{
						$set_data{'in_form'} = $set_data{'schema_name'};
					}
				}else{
					$set_data{'in_form'} = substr($set_data{'str'}, 0, $item);
				}
				$set_data{'str'} =  substr($set_data{'str'}, $item+1);
				# ?を削除
				&splitYen($set_data{'str'}, $item);
				# 設定値を取得
				&splitYen($set_data{'str'}, $item);
				if($item eq 98){
					$in_field[$i] = "Matching Ids";
				}else{
					$in_field[$i] = &replaceIdtoName($set_data{'object_name'}, $set_data{'in_form'}, $item);
				}
			}
			elsif($item eq "\*"){
				# 1を削除
				&splitYen($set_data{'str'}, $item);
				# *を削除
				&splitYen($set_data{'str'}, $item);
				# 1を削除
				&splitYen($set_data{'str'}, $item);
				# 設定値を取得
				&splitYen($set_data{'str'}, $item);
				if($item eq 98){
					$in_field[$i] = "Matching Ids";
				}else{
					$in_field[$i] = &replaceIdtoName($set_data{'object_name'}, $set_data{'schema_name'}, $item);
				}
			}
			else{
				&logOutput("ERROR", "replaceCodeAction", "102系エラー オブジェクト名=$set_data{'object_name'},処理中文字列=$set_data{'str'},元の文字列=$set_data{'sentence'}");
				return 0;
			}
			
			# Qualificationの取得
			if(substr($set_data{'str'}, 0, 1) eq 0){
				# 最初が0の場合は、条件なし
				&splitYen($set_data{'str'}, $item);
			}else{
				$set_data{'qual'} = &formatQualification($set_data{'str'}, $set_data{'object_name'}, $set_data{'schema_name'}, $set_data{'in_form'}, 1);
			}
			
			# If No Requests Matchを取得
			&splitYen($set_data{'str'}, $item);
			$set_data{'no_match'} = &replaceIfNoReqMatch($item);
	
			# If Multiple Requests Matchを取得
			&splitYen($set_data{'str'}, $item);
			$set_data{'mul_match'} = &replaceIfMulReqMatch($item);
			
			# 必要項目数を減らす
			$loop_cnt--;
		}
		## 103系 PROCESS ##
		elsif($item eq 103){
			# バイト数を取得
			&splitYen($set_data{'str'}, $item);
			
			# 値を設定
			$in_field[$i] = "\$PROCESS\$ " . substr($set_data{'str'}, 0, $item);
			$set_data{'str'} =  substr($set_data{'str'}, $item+1);
			
			# 必要項目数を減らす
			$loop_cnt--;
		}
		## 104系 演算 ##
		elsif($item eq 104){
			# 演算子を取得
			&splitYen($set_data{'str'}, $item);
			
			# 値を設定
			$in_field[$i] = &funcDecode104($item, $loop_cnt);
		}
		
		## 105系 関数 ##
		elsif($item eq 105){
			# 種類を取得
			&splitYen($set_data{'str'}, $item);
			$func_type = $item;
			
			# 引数を取得
			&splitYen($set_data{'str'}, $item);
			
			# 値を設定
			$in_field[$i] = "105\\" . "$func_type\\" . "$item\\";
			
			# 必要項目数を引数分増やす
			$loop_cnt = $loop_cnt + $item - 1;
		}
		
		## 107系 SQL ##
		elsif($item eq 107){
			# データソース設定
			$set_data{'dest'} = "SQL";
		
			# 1\@\ or 1\*\を削除
			&splitYen($set_data{'str'}, $item);
			&splitYen($set_data{'str'}, $item);
			
			# バイト数を取得
			&splitYen($set_data{'str'}, $item);
			
			# SQL文の取得
			# バイト数で文字列を取得
			&getStringByByte($object_name, $set_data{'qual'}, $set_data{'str'}, $item);
			$set_data{'qual'} = &replaceIdtoNameSentence($set_data{'object_name'}, $set_data{'schema_name'}, $set_data{'qual'});
			$set_data{'str'} =  substr($set_data{'str'}, 1);
			
			# SELECTで必要とする列番号を取得
			&splitYen($set_data{'str'}, $item);
			$in_field[$i] = "SQL " . $item;
			
			# If No Requests Matchを取得
			&splitYen($set_data{'str'}, $item);
			$set_data{'no_match'} = &replaceIfNoReqMatch($item);
	
			# If Multiple Requests Matchを取得
			&splitYen($set_data{'str'}, $item);
			$set_data{'mul_match'} = &replaceIfMulReqMatch($item);
			
			# 必要項目数を減らす
			$loop_cnt--;
		}
		
		## その他の場合はエラー##
		else{
			&logOutput("ERROR", "replaceCodeAction", "どれでもない系エラー オブジェクト名=$set_data{'object_name'},処理中文字列=$set_data{'str'},元の文字列=$set_data{'sentence'}");
			return 0;
		}
		$i++;
	}
	
	# 項目の組み立て
	for ($j = @in_field-1; $j >= 0; $j--) {
		# calc --の場合
		if($in_field[$j] eq "calc \-\-"){
			# -を付けて設定
			$in_field[$j] = "-" . $in_field[$j+1];
			splice(@in_field, $j+1, 1);
		}
		# calc [+-*\]の場合
		elsif(    $in_field[$j] eq "calc \+"
				|| $in_field[$j] eq "calc \-"
				|| $in_field[$j] eq "calc \*"
				|| $in_field[$j] eq "calc \/"){
			# 演算子で繋げる
			$in_field[$j] =~ s/calc //; 
			$in_field[$j] = "\(" . $in_field[$j+1] . " " . $in_field[$j] . " " . $in_field[$j+2] . "\)";
			splice(@in_field, $j+1, 2);
			
		}
		# 105の場合
		elsif(substr($in_field[$j], 0, 4) eq '105\\'){

			# 105を取得
			&splitYen($in_field[$j], $item);
			
			# 種類を取得
			&splitYen($in_field[$j], $item);
			$func_type = &funcDecode105($item);
			
			# 引数を取得
			&splitYen($in_field[$j], $item);

			# 引数分ループ
			for ($k = 1; $k <= $item; $k++) {
				$func_str = $func_str . $in_field[$j+$k] . ",";
			}
			splice(@in_field, $j+1, $item);
			$func_str = $func_type . "\(" . substr($func_str, 0, length($func_str)-1) . "\)";
			$in_field[$j] = $func_str;
		}
	}
	$set_data{'in_field'} = $in_field[0];
	return 0;
}

###############################
# Action系のファイル出力
#
# 第1引数	ファイルハンドル
# 第2引数	Actionの連想配列
###############################
sub funcOutPutAction(){
	my $action_type = $_[0];	# Action種類
	local(*FILE) = $_[1];		# ファイルハンドルを取得
	my $action = $_[2];			# Actionのデータ
	
	# ヘッダー出力
	print FILE join("\t"
						, "オブジェクト名"
						, "フォーム名"
						, "If Action/ Else Action"
						, "Action通番"
						, "action{}内の通番"
						, "Action種類"
						, "ガイド名"
						, "フィールド名"
						, "Field Access"
						, "Field Visibility"
						, "Field Label"
						, "Label Color"
						, "Refresh Tree/Table"
						, "Expand Collapse Tree Levels"
						, "Expand Collapse Panel"
						, "Field Drag"
						, "Field Drop"
						, "Option"
						, "Char Menu"
						, "Focus"
						, "オプション"
						, "SQL文"
						, "Close All Guides on Exit"
						, "値"
						, "値"
						, "種類"
						, "番号"
						, "Prompt Bar"
						, "内容"
						, "Window Type"
						, "Display Type"
						, "Target Location"
						, "Data Source"
						, "フォーム名"
						, "ビュー名"
						, "Show Close Button"
						, "Qualification"
						, "入力(フィールド名 | 値)"
						, "出力(フィールド名 | 値)"
						, "設定先フォーム名"
						, "設定先項目名"
						, "Data Destination"
						, "Qualification または SQL Query"
						, "If No Reuests Match"
						, "If Any Requests Match"
						, "設定元フォーム名"
						, "設定値"
						, "実行内容"
						, "設定先フォーム名"
						, "設定先項目名"
						, "Data Source"
						, "Qualification または SQL Query"
						, "If No Reuests Match"
						, "If Multiple Requests Match"
						, "設定元フォーム名"
						, "設定値"
						)."\n";
	
	# データ出力
	foreach $key (sort keys %$action){
		# キーの分解
		@split_key = split(/\t/, $key);
		
		# データの分解
		@split_data = split(/\t/, $$action{$key});
		
		# マッピング
		# $split_data[0]	$type
		# $split_data[1]	$call_guide
		# $split_data[2]	$change_field_name
		# $split_data[3]	$change_field_access
		# $split_data[4]	$change_field_visibility
		# $split_data[5]	$change_field_label
		# $split_data[6]	$change_field_label_color
		# $split_data[7]	$change_field_refresh
		# $split_data[8]	$change_field_levels
		# $split_data[9]	$change_field_panel
		# $split_data[10]	$change_field_drag
		# $split_data[11]	$change_field_drop
		# $split_data[12]	$change_field_option
		# $split_data[13]	$change_field_menu
		# $split_data[14]	$change_field_focus
		# $split_data[15]	$close_window
		# $split_data[16]	$direct_sql
		# $split_data[17]	$exit_guide
		# $split_data[18]	$goto
		# $split_data[19]	$goto_guide
		# $split_data[20]	$message_type
		# $split_data[21]	$message_number
		# $split_data[22]	$message_prompt
		# $split_data[23]	$message_content
		# $split_data[24]	$open_window_type
		# $split_data[25]	$open_window_ds_type
		# $split_data[26]	$open_window_target
		# $split_data[27]	$open_window_source
		# $split_data[28]	$open_window_schema
		# $split_data[29]	$open_window_view
		# $split_data[30]	$open_window_button
		# $split_data[31]	$open_window_qual
		# $split_data[32]	$open_window_input
		# $split_data[33]	$open_window_output
		# $split_data[34]	$push_field_out_form
		# $split_data[35]	$push_field_out_field
		# $split_data[36]	$push_field_dest
		# $split_data[37]	$push_field_qual
		# $split_data[38]	$push_field_no_match
		# $split_data[39]	$push_field_any_match
		# $split_data[40]	$push_field_in_form
		# $split_data[41]	$push_field_in_field
		# $split_data[42]	$run_process
		# $split_data[43]	$set_field_out_form
		# $split_data[44]	$set_field_out_field
		# $split_data[45]	$set_field_dest
		# $split_data[46]	$set_field_qual
		# $split_data[47]	$set_field_no_match
		# $split_data[48]	$set_field_mul_match
		# $split_data[49]	$set_field_in_form
		# $split_data[50]	$set_field_in_field
		
		# 整形不要なものはスキップ
		if(    $split_data[0] eq "commit-changes"
			|| $split_data[0] eq "Call Guide"
			|| $split_data[0] eq "Change Field"
			|| $split_data[0] eq "Close Window"
			|| $split_data[0] eq "exit guide"
			|| $split_data[0] eq "goto action"
			|| $split_data[0] eq "Message"
			|| $split_data[0] eq "Run Process"
			){
			# 特になにもしない
		}
		# Direct SQLの場合
		elsif($split_data[0] eq "Direct SQL"){
			$split_data[16] = &replaceIdtoNameSentence($split_key[0], $split_key[1], $split_data[16]);
			$split_data[16] = &replaceDefault($split_key[0], $split_data[16]);
		}
		# Open Windowの場合
		elsif($split_data[0] eq "Open Window"){
			# open_window_schema
			$split_data[28] = &replaceIdtoNameSentence($split_key[0], $split_key[1], $split_data[28]);
			
			# open_window_qualの整形
			$split_data[31] = &formatQualification($split_data[31], $split_key[0], $split_key[1], $split_data[28], 1);
			
			# Window Typeに応じて出力要否が変わる
			if(   $split_data[24] eq "Dialog"
			   || $split_data[24] eq "Search"
			   || $split_data[24] eq "Submit"
			   || $split_data[24] eq "Popup"
			){
				# open-inputの整形
				if($split_data[32] ne "-"){
					%set_data = ();
					$set_data{'object_name'}=$split_key[0];
					$set_data{'schema_name'}=$split_key[1];
					$set_data{'server_name'}=$split_data[28];
					$set_data{'alfl'}=$action_type;
					$set_data{'open_inout'}="OpenInput";
					$set_data{'sentence'}=$split_data[32];
				
					$split_data[32] = &formatOpenData(@set_data);
				}
				# open-outputの整形
				if($split_data[33] ne "-"){
					%set_data = ();
					$set_data{'object_name'}=$split_key[0];
					$set_data{'schema_name'}=$split_key[1];
					$set_data{'server_name'}=$split_data[28];
					$set_data{'alfl'}=$action_type;
					$set_data{'open_inout'}="OpenOutput";
					$set_data{'sentence'}=$split_data[33];
				
					$split_data[33] = &formatOpenData(@set_data);
				}
			}
		}
		# push-fieldの場合
		elsif($split_data[0] eq "push-field"){
			%set_data = ();
			$set_data{'object_name'}=$split_key[0];
			$set_data{'schema_name'}=$split_key[1];
			$set_data{'alfl'}=$action_type;
			$set_data{'push_set'}="Push";
			$set_data{'sentence'}=$split_data[34];
			
			&formatPushField(@set_data);
			$split_data[34] = $set_data{'out_form'};
			$split_data[35] = $set_data{'out_field'};
			$split_data[36] = $set_data{'dest'};
			$split_data[37] = $set_data{'qual'};
			$split_data[38] = $set_data{'no_match'};
			$split_data[39] = $set_data{'any_match'};
			$split_data[40] = $set_data{'in_form'};
			$split_data[41] = $set_data{'in_field'};
		}
		# set-fieldの場合
		elsif($split_data[0] eq "set-field"){
			%set_data = ();
			$set_data{'object_name'}=$split_key[0];
			$set_data{'schema_name'}=$split_key[1];
			$set_data{'alfl'}=$action_type;
			$set_data{'push_set'}="Set";
			$set_data{'sentence'}=$split_data[43];
			
			&formatSetField(@set_data);
			$split_data[43] = $set_data{'out_form'};
			$split_data[44] = $set_data{'out_field'};
			$split_data[45] = $set_data{'dest'};
			$split_data[46] = $set_data{'qual'};
			$split_data[47] = $set_data{'no_match'};
			$split_data[48] = $set_data{'mul_match'};
			$split_data[49] = $set_data{'in_form'};
			$split_data[50] = $set_data{'in_field'};
		}
		# 出力処理
		print FILE join("\t"
						, $split_key[0]
						, $split_key[1]
						, substr($split_key[2], 2)
						, sprintf("%d", $split_key[3])
						, sprintf("%d", $split_key[4])
						, $split_data[0]
						, $split_data[1]
						, $split_data[2]
						, $split_data[3]
						, $split_data[4]
						, $split_data[5]
						, $split_data[6]
						, $split_data[7]
						, $split_data[8]
						, $split_data[9]
						, $split_data[10]
						, $split_data[11]
						, $split_data[12]
						, $split_data[13]
						, $split_data[14]
						, $split_data[15]
						, $split_data[16]
						, $split_data[17]
						, $split_data[18]
						, $split_data[19]
						, $split_data[20]
						, $split_data[21]
						, $split_data[22]
						, $split_data[23]
						, $split_data[24]
						, $split_data[25]
						, $split_data[26]
						, $split_data[27]
						, $split_data[28]
						, $split_data[29]
						, $split_data[30]
						, $split_data[31]
						, $split_data[32]
						, $split_data[33]
						, $split_data[34]
						, $split_data[35]
						, $split_data[36]
						, $split_data[37]
						, $split_data[38]
						, $split_data[39]
						, $split_data[40]
						, $split_data[41]
						, $split_data[42]
						, $split_data[43]
						, $split_data[44]
						, $split_data[45]
						, $split_data[46]
						, $split_data[47]
						, $split_data[48]
						, $split_data[49]
						, $split_data[50]
						)."\n";
	}
	
}

###############################
# エラー出力
#
# 第1引数	識別(INFO, WARNING, ERROR)
# 第2引数	発生箇所
# 第3引数	メッセージ
###############################
sub logOutput{
	my $level = $_[0];		# 識別
	my $place = $_[1];		# 発生個所
	my $message = $_[2];	# メッセージ
	my $output = "";		# 出力する文字
	
	$output = "【$level】発生個所:$place\t$message" ."\n";
	
	print $output;
	print OUT_WORK $output;
	
	return 0
}

###############################
# \マークの分割
#
# 第1引数	分割したい文字列、分割後の残りの文字列で上書き
# 第2引数	取得したい文字
###############################
sub splitYen{
	$target = $_[0];	# 分割対象とする文字列
	
	# 何文字目にあるか取得
	$pos = index($target, "\\");
	
	$_[0] = substr($target, $pos+1);	# 渡された第1引数の値を変更
	$_[1] = substr($target, 0, $pos);	# 渡された第2引数の値を変更
	
	return 0
}

###############################
# 指定バイト数の文字列取得
#
# 第1引数	オブジェクト名
# 第2引数	取得したい文字
# 第3引数	取得元文字列
# 第4引数	バイト数
###############################
sub getStringByByte{
	my $object_name = $_[0];	# オブジェクト名
	$get_byte_string = "";		# 取得したい文字
	$get_byte_qual = $_[2];		# 取得元文字列
	my $byte = $_[3];			# バイト数
	my $i;						# 制御文字
	
	for ($i = 1; $i <= $byte; $i++) {
		# 半角の場合
		if(substr($get_byte_qual, 0 ,1) =~ /^[\x00-\x7F]/){
			$get_byte_string = $get_byte_string . substr($get_byte_qual, 0 ,1);
			$get_byte_qual =  substr($get_byte_qual, 1);
		# 全角の場合
		}else{
			$get_byte_string = $get_byte_string . substr($get_byte_qual, 0 ,1);
			$get_byte_qual =  substr($get_byte_qual, 1);
			$i = $i + 2;
		}
	}
	
	$_[1] = $get_byte_string;	# 渡された第2引数の値を変更
	$_[2] = $get_byte_qual;		# 渡された第3引数の値を変更
	
	return 0
}
