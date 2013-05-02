/*
Ted, a simple text editor/IDE.

Copyright 2012, Blitz Research Ltd.

See LICENSE.TXT for licensing terms.
*/

#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "codeeditor.h"
#include "prefsdialog.h"
#include "projecttreemodel.h"
#include "debugtreemodel.h"
#include "finddialog.h"
#include "prefs.h"
#include "process.h"
#include "findinfilesdialog.h"

#include <QHostInfo>

#define TED_VERSION "1.17"

#define SETTINGS_VERSION 2

#ifdef Q_OS_WIN
#define HOST QString("_winnt")
#elif defined( Q_OS_MAC )
#define HOST QString("_macos")
#elif defined( Q_OS_LINUX )
#define HOST QString("_linux")
#else
#define HOST QString("")
#endif

#define _QUOTE(X) #X
#define _STRINGIZE( X ) _QUOTE(X)

static MainWindow *mainWindow;

void cdebug( const QString &q ){
    if( mainWindow ) mainWindow->cdebug( q );
}

//***** MainWindow *****
//
MainWindow::MainWindow(QWidget *parent) : QMainWindow( parent ),_ui( new Ui::MainWindow ){

    mainWindow=this;

#ifdef Q_OS_MAC
    QCoreApplication::instance()->setAttribute( Qt::AA_DontShowIconsInMenus );
#endif

    QCoreApplication::setOrganizationName( "Blitz Research Ltd" );
    QCoreApplication::setOrganizationDomain( "blitzresearchltd.com" );
    QCoreApplication::setApplicationName( "Ted" );

    QString comp=QHostInfo::localHostName();

    QString cfgPath=QCoreApplication::applicationDirPath();
#ifdef Q_OS_MAC
    cfgPath=extractDir(extractDir(extractDir(cfgPath)))+"/ted_macos_"+comp+".ini";
#elif defined(Q_OS_WIN)
    cfgPath+="/ted_winnt_"+comp+".ini";
#elif defined(Q_OS_LINUX)
    cfgPath+="/ted_linux_"+comp+".ini";
#endif
    QSettings::setDefaultFormat( QSettings::IniFormat );
    QSettings::setPath( QSettings::IniFormat,QSettings::UserScope,cfgPath );

    //Enables pdf viewing!
    QWebSettings::globalSettings()->setAttribute( QWebSettings::PluginsEnabled,true );

    //setIconSize( QSize(20,20) );

    _ui->setupUi( this );

    _codeEditor=0;
    _lockedEditor=0;
    _helpWidget=0;

    //docking options
    setCorner( Qt::TopLeftCorner,Qt::LeftDockWidgetArea );
    setCorner( Qt::BottomLeftCorner,Qt::LeftDockWidgetArea );
    setCorner( Qt::TopRightCorner,Qt::RightDockWidgetArea );
    setCorner( Qt::BottomRightCorner,Qt::RightDockWidgetArea );

    //status bar widget
    _statusWidget=new QLabel;
    statusBar()->addPermanentWidget( _statusWidget );

    //targets combobox
    _targetsWidget=new QComboBox;
    _ui->buildToolBar->addWidget( _targetsWidget );

    _configsWidget=new QComboBox;
    _configsWidget->addItem( "Debug" );
    _configsWidget->addItem( "Release" );
    _ui->buildToolBar->addWidget( _configsWidget );

    _indexWidget=new QComboBox;
    _indexWidget->setFixedWidth( 120 );
    _indexWidget->setEditable( true );
    _indexWidget->setInsertPolicy( QComboBox::NoInsert );
    _ui->helpToolBar->addWidget( _indexWidget );
//    connect( _indexWidget,SIGNAL(currentIndexChanged(QString)),SLOT(onShowHelp(QString)) );

    //init central tab widget
    _mainTabWidget=new QTabWidget;
    _mainTabWidget->setMovable( true );
    _mainTabWidget->setTabsClosable( true );

    setCentralWidget( _mainTabWidget );
    connect( _mainTabWidget,SIGNAL(currentChanged(int)),SLOT(onMainTabChanged(int)) );
    connect( _mainTabWidget,SIGNAL(tabCloseRequested(int)),SLOT(onCloseMainTab(int)) );

    //init console widgets
    _consoleProc=0;
    _consoleTextWidget=new QTextEdit;
    _consoleTextWidget->setReadOnly( true );
    //_consoleTextWidget->setAcceptRichText( false );
    //_consoleTextWidget->setAutoFormatting( QTextEdit::AutoNone );
    //
    _consoleDockWidget=new QDockWidget;
    _consoleDockWidget->setObjectName( "consoleDockWidget" );
    _consoleDockWidget->setAllowedAreas( Qt::TopDockWidgetArea | Qt::BottomDockWidgetArea );
    _consoleDockWidget->setWindowTitle( "Console" );
    _consoleDockWidget->setWidget( _consoleTextWidget );
    addDockWidget( Qt::BottomDockWidgetArea,_consoleDockWidget );
    connect( _consoleDockWidget,SIGNAL(visibilityChanged(bool)),SLOT(onDockVisibilityChanged(bool)) );

    //init browser widgets
    _projectTreeModel=new ProjectTreeModel;
    _projectTreeWidget=new QTreeView;
    _projectTreeWidget->setHeaderHidden( true );
    _projectTreeWidget->setModel( _projectTreeModel );
    _projectTreeWidget->hideColumn( 1 );
    _projectTreeWidget->hideColumn( 2 );
    _projectTreeWidget->hideColumn( 3 );
    _projectTreeWidget->setContextMenuPolicy( Qt::CustomContextMenu );
    connect( _projectTreeWidget,SIGNAL(doubleClicked(const QModelIndex&)),SLOT(onFileClicked(const QModelIndex&)) );
    connect( _projectTreeWidget,SIGNAL(customContextMenuRequested(const QPoint&)),SLOT(onProjectMenu(const QPoint&)) );

    _emptyCodeWidget=new QWidget;

    _debugTreeModel=0;
    _debugTreeWidget=new QTreeView;
    _debugTreeWidget->setHeaderHidden( true );

    _browserTabWidget=new QTabWidget;
    _browserTabWidget->addTab( _projectTreeWidget,"Projects" );
    _browserTabWidget->addTab( _emptyCodeWidget,"Code" );
    _browserTabWidget->addTab( _debugTreeWidget,"Debug" );

    _browserDockWidget=new QDockWidget;
    _browserDockWidget->setObjectName( "browserDockWidget" );
    _browserDockWidget->setAllowedAreas( Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea );
    _browserDockWidget->setWindowTitle( "Browser" );
    _browserDockWidget->setWidget( _browserTabWidget );

    addDockWidget( Qt::RightDockWidgetArea,_browserDockWidget );
    connect( _browserDockWidget,SIGNAL(visibilityChanged(bool)),SLOT(onDockVisibilityChanged(bool)) );

#ifdef Q_OS_WIN
    _ui->actionFileNext->setShortcut( QKeySequence( "Ctrl+Tab" ) );
    _ui->actionFilePrevious->setShortcut( QKeySequence( "Ctrl+Shift+Tab" ) );
#else
    _ui->actionFileNext->setShortcut( QKeySequence( "Meta+Tab" ) );
    _ui->actionFilePrevious->setShortcut( QKeySequence( "Meta+Shift+Tab" ) );
#endif

    _projectPopupMenu=new QMenu;
    _projectPopupMenu->addAction( _ui->actionNewFile );
    _projectPopupMenu->addAction( _ui->actionNewFolder );
    _projectPopupMenu->addSeparator();
    _projectPopupMenu->addAction( _ui->actionEditFindInFiles );
    _projectPopupMenu->addSeparator();
    _projectPopupMenu->addAction( _ui->actionOpen_on_Desktop );
    _projectPopupMenu->addSeparator();
    _projectPopupMenu->addAction( _ui->actionCloseProject );

    _filePopupMenu=new QMenu;
    _filePopupMenu->addAction( _ui->actionOpen_on_Desktop );
    _filePopupMenu->addSeparator();
    _filePopupMenu->addAction( _ui->actionRenameFile );
    _filePopupMenu->addAction( _ui->actionDeleteFile );

    _dirPopupMenu=new QMenu;
    _dirPopupMenu->addAction( _ui->actionNewFile );
    _dirPopupMenu->addAction( _ui->actionNewFolder );
    _dirPopupMenu->addSeparator();
    _dirPopupMenu->addAction( _ui->actionEditFindInFiles );
    _dirPopupMenu->addSeparator();
    _dirPopupMenu->addAction( _ui->actionOpen_on_Desktop );
    _dirPopupMenu->addSeparator();
    _dirPopupMenu->addAction( _ui->actionRenameFile );
    _dirPopupMenu->addAction( _ui->actionDeleteFile );

    connect( _ui->actionFileQuit,SIGNAL(triggered()),SLOT(onFileQuit()) );

    readSettings();

    _prefsDialog=new PrefsDialog( this );
    _prefsDialog->readSettings();

    _findDialog=new FindDialog( this );
    _findDialog->readSettings();
    connect( _findDialog,SIGNAL(findReplace(int)),SLOT(onFindReplace(int)) );

    _findInFilesDialog=new FindInFilesDialog( 0 );
    _findInFilesDialog->readSettings();
    connect( _findInFilesDialog,SIGNAL(showCode(QString,int,int)),SLOT(onShowCode(QString,int,int)) );

    loadHelpIndex();

    parseAppArgs();

    updateWindowTitle();

    updateActions();

    statusBar()->showMessage( "Ready." );
}

MainWindow::~MainWindow(){

    delete _ui;
}

//***** private methods *****

void MainWindow::loadHelpIndex(){
    if( _monkeyPath.isEmpty() ) return;

    QFile file( _monkeyPath+"/docs/html/index.txt" );
    if( !file.open( QIODevice::ReadOnly ) ) return;

    QTextStream stream( &file );

    stream.setCodec( "UTF-8" );

    QString text=stream.readAll();

    file.close();

    QStringList lines=text.split('\n');

    _indexWidget->disconnect();

    _indexWidget->clear();

    for( int i=0;i<lines.count();++i ){

        QString line=lines.at( i );

        int j=line.indexOf( ':' );
        if( j==-1 ) continue;

        QString topic=line.left(j);
        QString url="file:///"+_monkeyPath+"/docs/html/"+line.mid(j+1);

        _indexWidget->addItem( topic );

        _helpUrls.insert( topic,url );
    }

    connect( _indexWidget,SIGNAL(currentIndexChanged(QString)),SLOT(onShowHelp(QString)) );
}

void MainWindow::parseAppArgs(){
    QStringList args=QApplication::arguments();
    for( int i=1;i<args.size();++i ){
        QString arg=fixPath( args.at(i) );
        if( QFile::exists( arg ) ){
            openFile( arg,true );
        }
    }
}

bool MainWindow::isBuildable( CodeEditor *editor ){
    if( !editor ) return false;
    if( editor->fileType()=="monkey" ) return !_monkeyPath.isEmpty();
    if( editor->fileType()=="bmx" ) return !_blitzmaxPath.isEmpty();
    return false;
}

QString MainWindow::widgetPath( QWidget *widget ){
    if( CodeEditor *editor=qobject_cast<CodeEditor*>( widget ) ){
        return editor->path();
    }else if( QWebView *webView=qobject_cast<QWebView*>( widget ) ){
        return webView->url().toString();
    }
    return "";
}

CodeEditor *MainWindow::editorWithPath( const QString &path ){
    for( int i=0;i<_mainTabWidget->count();++i ){
        if( CodeEditor *editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) ) ){
            if( editor->path()==path ) return editor;
        }
    }
    return 0;
}

QWidget *MainWindow::newFile( const QString &cpath ){

    QString path=cpath;

    if( path.isEmpty() ){

        path=fixPath( QFileDialog::getSaveFileName( this,"New File",_defaultDir,"Source Files (*.monkey *.bmx *.cpp *.cs *.js *.as *.java *.txt)" ) );
        if( path.isEmpty() ) return 0;
    }

    QFile file( path );
    if( !file.open( QIODevice::WriteOnly | QIODevice::Truncate ) ){
        QMessageBox::warning( this,"New file","Failed to create new file: "+path );
        return 0;
    }
    file.close();

    return openFile( path,true );
}

QWidget *MainWindow::openFile( const QString &cpath,bool addToRecent ){

    if( isUrl( cpath ) ){
        QWebView *webView=0;
        for( int i=0;i<_mainTabWidget->count();++i ){
            if( webView=qobject_cast<QWebView*>( _mainTabWidget->widget( i ) ) ) break;
        }
        if( !webView ){
            webView=new QWebView;
            webView->page()->setLinkDelegationPolicy( QWebPage::DelegateAllLinks );
            connect( webView,SIGNAL(linkClicked(QUrl)),SLOT(onLinkClicked(QUrl)) );
            _mainTabWidget->addTab( webView,"Help" );
        }

        webView->setUrl( cpath );

        if( webView!=_mainTabWidget->currentWidget() ){
            _mainTabWidget->setCurrentWidget( webView );
        }else{
            updateWindowTitle();
        }

        return webView;
    }

    QString path=cpath;

    if( path.isEmpty() ){

        path=fixPath( QFileDialog::getOpenFileName( this,"Open File",_defaultDir,"Source Files (*.monkey *.cpp *.cs *.js *.as *.java);;Image Files(*.jpg *.png *.bmp);;All Files(*.*)" ) );
        if( path.isEmpty() ) return 0;

        _defaultDir=extractDir( path );
    }

    CodeEditor *editor=editorWithPath( path );
    if( editor ){
        _mainTabWidget->setCurrentWidget( editor );
        return editor;
    }

    editor=new CodeEditor;
    if( !editor->open( path ) ){
        delete editor;
        QMessageBox::warning( this,"Open File Error","Error opening file: "+path );
        return 0;
    }

    connect( editor,SIGNAL(textChanged()),SLOT(onTextChanged()) );
    connect( editor,SIGNAL(cursorPositionChanged()),SLOT(onCursorPositionChanged()) );

    _mainTabWidget->addTab( editor,stripDir( path ) );
    _mainTabWidget->setCurrentWidget( editor );

    if( addToRecent ){
        QMenu *menu=_ui->menuRecent_Files;
        QList<QAction*> actions=menu->actions();
        bool found=false;
        for( int i=0;i<actions.size();++i ){
            if( actions[i]->text()==path ){
                found=true;
                break;
            }
        }
        if( !found ){
            for( int i=19;i<actions.size();++i ){
                menu->removeAction( actions[i] );
            }
            QAction *action=new QAction( path,menu );
            if( actions.size() ){
                menu->insertAction( actions[0],action );
            }else{
                menu->addAction( action );
            }
            connect( action,SIGNAL(triggered()),this,SLOT(onFileOpenRecent()) );
        }
    }

    return editor;
}

bool MainWindow::saveFile( QWidget *widget,const QString &cpath ){

    QString path=cpath;

    CodeEditor *editor=qobject_cast<CodeEditor*>( widget );
    if( !editor ) return true;

    if( path.isEmpty() ){

        _mainTabWidget->setCurrentWidget( editor );

        path=fixPath( QFileDialog::getSaveFileName( this,"Save File As",editor->path(),"Source Files (*.monkey *.cpp *.cs *.js *.as *.java)" ) );
        if( path.isEmpty() ) return false;

    }else if( !editor->modified() ){
        return true;
    }

    if( !editor->save( path ) ){
        QMessageBox::warning( this,"Save File Error","Error saving file: "+path );
        return false;
    }

    updateTabLabel( editor );

    updateWindowTitle();

    updateActions();

    return true;
}

bool MainWindow::closeFile( QWidget *widget,bool really ){
    if( !widget ) return true;

    CodeEditor *editor=qobject_cast<CodeEditor*>( widget );

    if( editor && editor->modified() ){

        _mainTabWidget->setCurrentWidget( editor );

        QMessageBox msgBox;
        msgBox.setText( editor->path()+" has been modified." );
        msgBox.setInformativeText( "Do you want to save your changes?" );
        msgBox.setStandardButtons( QMessageBox::Save|QMessageBox::Discard|QMessageBox::Cancel );
        msgBox.setDefaultButton( QMessageBox::Save );

        int ret=msgBox.exec();

        if( ret==QMessageBox::Save ){
            if( !saveFile( editor,editor->path() ) ) return false;
        }else if( ret==QMessageBox::Cancel ){
            return false;
        }else if( ret==QMessageBox::Discard ){
        }
    }

    if( !really ) return true;

    if( widget==_codeEditor ){
        _codeEditor=0;
    }else if( widget==_helpWidget ){
        _helpWidget=0;
    }
    if( widget==_lockedEditor ){
        _lockedEditor=0;
    }

    _mainTabWidget->removeTab( _mainTabWidget->indexOf( widget ) );

    delete widget;

    return true;
}

bool MainWindow::confirmQuit(){

    writeSettings();

    _prefsDialog->writeSettings();

    _findDialog->writeSettings();

    _findInFilesDialog->writeSettings();

    for( int i=0;i<_mainTabWidget->count();++i ){

        CodeEditor *editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) );

        if( editor && !closeFile( editor,false ) ) return false;
    }

    return true;
}

void MainWindow::closeEvent( QCloseEvent *event ){

    if( confirmQuit() ){
        _findInFilesDialog->close();
        event->accept();
    }else{
        event->ignore();
    }
}

//Settings...
//
bool MainWindow::isValidMonkeyPath( const QString &path ){
    QString transcc="transcc"+HOST;
#ifdef Q_OS_WIN
    transcc+=".exe";
#endif
    return QFile::exists( path+"/bin/"+transcc );
}

bool MainWindow::isValidBlitzmaxPath( const QString &path ){
#ifdef Q_OS_WIN
    QString bmk="bmk.exe";
#else
    QString bmk="bmk";
#endif
    return QFile::exists( path+"/bin/"+bmk );
}

QString MainWindow::defaultMonkeyPath(){
    QString path=QApplication::applicationDirPath();
    while( !path.isEmpty() ){
        if( isValidMonkeyPath( path ) ) return path;
        path=extractDir( path );
    }
    return "";
}

void MainWindow::enumTargets(){
    if( _monkeyPath.isEmpty() ) return;

    QString cmd="\""+_monkeyPath+"/bin/transcc"+HOST+"\"";

    Process proc;
    if( !proc.start( cmd ) ) return;

    _targetsWidget->clear();

    QString sol="Valid targets: ";
    QString ver="TRANS monkey compiler V";

    while( proc.waitLineAvailable( 0 ) ){
        QString line=proc.readLine( 0 );
        if( line.startsWith( ver ) ){
            _transVersion=line.mid( ver.length() );
        }else if( line.startsWith( sol ) ){
            line=line.mid( sol.length() );
            QStringList bits=line.split( ' ' );
            for( int i=0;i<bits.count();++i ){
                QString bit=bits[i];
                if( !bit.isEmpty() ) _targetsWidget->addItem( bit.replace( '_',' ' ) );
            }
        }
    }
}

void MainWindow::readSettings(){

    QSettings settings;

    Prefs *prefs=Prefs::prefs();

    _buildMonkeyCmd="\"${MONKEYPATH}/bin/transcc"+HOST+"\" -target=${TARGET} -config=${CONFIG} \"${FILEPATH}\"";
    _runMonkeyCmd="\"${MONKEYPATH}/bin/transcc"+HOST+"\" -target=${TARGET} -config=${CONFIG} -run \"${FILEPATH}\"";

    _buildBmxCmd="\"${BLITZMAXPATH}/bin/bmk\" makeapp -a -x ${FILEPATH}";
    _runBmxCmd="\"${BLITZMAXPATH}/bin/bmk\" makeapp -a -r -x ${FILEPATH}";

    if( settings.value( "settingsVersion" ).toInt()<1 ){

        prefs->setValue( "fontFamily","Courier" );
        prefs->setValue( "fontSize",12 );
        prefs->setValue( "tabSize",4 );
        prefs->setValue( "backgroundColor",QColor( 255,255,255 ) );
        prefs->setValue( "defaultColor",QColor( 0,0,0 ) );
        prefs->setValue( "numbersColor",QColor( 0,0,255 ) );
        prefs->setValue( "stringsColor",QColor( 170,0,255 ) );
        prefs->setValue( "identifiersColor",QColor( 0,0,0 ) );
        prefs->setValue( "keywordsColor",QColor( 0,85,255 ) );
        prefs->setValue( "commentsColor",QColor( 0,128,128 ) );
        prefs->setValue( "highlightColor",QColor( 255,255,128 ) );
        prefs->setValue( "smoothFonts",true );

        _monkeyPath=defaultMonkeyPath();
        prefs->setValue( "monkeyPath",_monkeyPath );

        _blitzmaxPath="";
        prefs->setValue( "blitzmaxPath",_blitzmaxPath );

        if( !_monkeyPath.isEmpty() ){
            _projectTreeModel->addProject( _monkeyPath );
        }

        enumTargets();

        onHelpHome();

        return;
    }

    _monkeyPath=defaultMonkeyPath();

    QString prefsMonkeyPath=prefs->getString( "monkeyPath" );

    if( _monkeyPath.isEmpty() ){

        _monkeyPath=prefsMonkeyPath;

        if( !isValidMonkeyPath( _monkeyPath ) ){
            _monkeyPath="";
            prefs->setValue( "monkeyPath",_monkeyPath );
            QMessageBox::warning( this,"Monkey Path Error","Invalid Monkey path!\n\nPlease select correct path from the File..Options dialog" );
        }

    }else if( _monkeyPath!=prefsMonkeyPath ){
        prefs->setValue( "monkeyPath",_monkeyPath );
        QMessageBox::information( this,"Monkey Path Updated","Monkey path has been updated to "+_monkeyPath );
    }

    _blitzmaxPath=prefs->getString( "blitzmaxPath" );
    if( !_blitzmaxPath.isEmpty() && !isValidBlitzmaxPath( _blitzmaxPath ) ){
        _blitzmaxPath="";
        prefs->setValue( "blitzmaxPath",_blitzmaxPath );
        QMessageBox::warning( this,"BlitzMax Path Error","Invalid BlitzMax path!\n\nPlease select correct path from the File..Options dialog" );
    }

    enumTargets();

    settings.beginGroup( "mainWindow" );
    restoreGeometry( settings.value( "geometry" ).toByteArray() );
    restoreState( settings.value( "state" ).toByteArray() );
    settings.endGroup();

    int n=settings.beginReadArray( "openProjects" );
    for( int i=0;i<n;++i ){
        settings.setArrayIndex( i );
        QString path=fixPath( settings.value( "path" ).toString() );
        if( QFile::exists( path ) ) _projectTreeModel->addProject( path );
    }
    settings.endArray();

    n=settings.beginReadArray( "openDocuments" );
    for( int i=0;i<n;++i ){
        settings.setArrayIndex( i );
        QString path=fixPath( settings.value( "path" ).toString() );
        if( isUrl( path ) ){
            openFile( path,false );
        }else{
            if( QFile::exists( path ) ) openFile( path,false );
        }
    }
    settings.endArray();

    n=settings.beginReadArray( "recentFiles" );
    for( int i=0;i<n;++i ){
        settings.setArrayIndex( i );
        QString path=fixPath( settings.value( "path" ).toString() );
        if( QFile::exists( path ) ) _ui->menuRecent_Files->addAction( path,this,SLOT(onFileOpenRecent()) );
    }
    settings.endArray();

    settings.beginGroup( "buildSettings" );
    QString target=settings.value( "target" ).toString();
    if( !target.isEmpty() ){
        for( int i=0;i<_targetsWidget->count();++i ){
            if( _targetsWidget->itemText(i)==target ){
                _targetsWidget->setCurrentIndex( i );
                break;
            }
        }
    }
    QString config=settings.value( "config" ).toString();
    if( !config.isEmpty() ){
        for( int i=0;i<_configsWidget->count();++i ){
            if( _configsWidget->itemText(i)==config ){
                _configsWidget->setCurrentIndex( i );
                break;
            }
        }
    }
    QString locked=settings.value( "locked" ).toString();
    if( !locked.isEmpty() ){
        if( CodeEditor *editor=editorWithPath( locked ) ){
            _lockedEditor=editor;
            updateTabLabel( editor );
        }
    }
    settings.endGroup();

    if( settings.value( "settingsVersion" ).toInt()<2 ){
        return;
    }

    _defaultDir=fixPath( settings.value( "defaultDir" ).toString() );
}

void MainWindow::writeSettings(){
    QSettings settings;

    settings.setValue( "settingsVersion",SETTINGS_VERSION );

    settings.beginGroup( "mainWindow" );
    settings.setValue( "geometry",saveGeometry() );
    settings.setValue( "state",saveState() );
    settings.endGroup();

    settings.beginWriteArray( "openProjects" );
    QVector<QString> projs=_projectTreeModel->projects();
    for( int i=0;i<projs.size();++i ){
        settings.setArrayIndex(i);
        settings.setValue( "path",projs[i] );
    }
    settings.endArray();

    settings.beginWriteArray( "openDocuments" );
    int n=0;
    for( int i=0;i<_mainTabWidget->count();++i ){
        QString path=widgetPath( _mainTabWidget->widget( i ) );
        if( path.isEmpty() ) continue;
        settings.setArrayIndex( n++ );
        settings.setValue( "path",path );
    }
    settings.endArray();

    settings.beginWriteArray( "recentFiles" );
    QList<QAction*> rfiles=_ui->menuRecent_Files->actions();
    for( int i=0;i<rfiles.size();++i ){
        settings.setArrayIndex( i );
        settings.setValue( "path",rfiles[i]->text() );
    }
    settings.endArray();

    settings.beginGroup( "buildSettings" );
    settings.setValue( "target",_targetsWidget->currentText() );
    settings.setValue( "config",_configsWidget->currentText() );
    settings.setValue( "locked",_lockedEditor ? _lockedEditor->path() : "" );
    settings.endGroup();

    settings.setValue( "defaultDir",_defaultDir );
}

//Actions...
//
void MainWindow::updateActions(){

    bool ed=_codeEditor!=0;
    bool db=_debugTreeModel!=0;
    bool wr=ed && !_codeEditor->isReadOnly();
    bool sel=ed && _codeEditor->textCursor().hasSelection();

    bool saveAll=false;
    for( int i=0;i<_mainTabWidget->count();++i ){
        if( CodeEditor *editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) ) ){
            if( editor->modified() ) saveAll=true;
        }
    }

    //file menu
    _ui->actionClose->setEnabled( ed || _helpWidget );
    _ui->actionClose_All->setEnabled( _mainTabWidget->count()>1 || (_mainTabWidget->count()==1 && !_helpWidget) );
    _ui->actionClose_Others->setEnabled( _mainTabWidget->count()>1 );
    _ui->actionSave->setEnabled( ed && _codeEditor->modified() );
    _ui->actionSave_As->setEnabled( ed );
    _ui->actionSave_All->setEnabled( saveAll );
    _ui->actionFileNext->setEnabled( _mainTabWidget->count()>1 );
    _ui->actionFilePrevious->setEnabled( _mainTabWidget->count()>1 );

    //edit menu
    _ui->actionEditUndo->setEnabled( wr && _codeEditor->document()->isUndoAvailable() );
    _ui->actionEditRedo->setEnabled( wr && _codeEditor->document()->isRedoAvailable() );
    _ui->actionEditCut->setEnabled( wr && sel );
    _ui->actionEditCopy->setEnabled( sel );
    _ui->actionEditPaste->setEnabled( wr );
    _ui->actionEditDelete->setEnabled( sel );
    _ui->actionEditSelectAll->setEnabled( ed );
    _ui->actionEditFind->setEnabled( ed );
    _ui->actionEditFindNext->setEnabled( ed );
    _ui->actionEditGoto->setEnabled( ed );

    //view menu - not totally sure why !isHidden works but isVisible doesn't...
    _ui->actionViewFile->setChecked( !_ui->fileToolBar->isHidden() );
    _ui->actionViewEdit->setChecked( !_ui->editToolBar->isHidden() );
    _ui->actionViewBuild->setChecked( !_ui->buildToolBar->isHidden() );
    _ui->actionViewHelp->setChecked( !_ui->helpToolBar->isHidden() );
    _ui->actionViewConsole->setChecked( !_consoleDockWidget->isHidden() );
    _ui->actionViewBrowser->setChecked( !_browserDockWidget->isHidden() );

    //build menu
    CodeEditor *buildEditor=_lockedEditor ? _lockedEditor : _codeEditor;
    bool canBuild=!_consoleProc && isBuildable( buildEditor );
    bool canTrans=canBuild && buildEditor->fileType()=="monkey";
    _ui->actionBuildBuild->setEnabled( canBuild );
    _ui->actionBuildRun->setEnabled( canBuild || db );
    _ui->actionBuildCheck->setEnabled( canTrans );
    _ui->actionBuildUpdate->setEnabled( canTrans );
    _ui->actionStep->setEnabled( db );
    _ui->actionStep_In->setEnabled( db );
    _ui->actionStep_Out->setEnabled( db );
    _ui->actionKill->setEnabled( _consoleProc!=0 );
    _ui->actionLock_Build_File->setEnabled( _codeEditor!=_lockedEditor && isBuildable( _codeEditor ) );
    _ui->actionUnlock_Build_File->setEnabled( _lockedEditor!=0 );

    //help menu
    _ui->actionHelpBack->setEnabled( _helpWidget!=0 );
    _ui->actionHelpForward->setEnabled( _helpWidget!=0 );
    _ui->actionHelpQuickHelp->setEnabled( _codeEditor!=0 );
    _ui->actionHelpRebuild->setEnabled( _consoleProc==0 );
}

void MainWindow::updateWindowTitle(){
    QWidget *widget=_mainTabWidget->currentWidget();
    if( CodeEditor *editor=qobject_cast<CodeEditor*>( widget ) ){
        setWindowTitle( editor->path() );
    }else if( QWebView *webView=qobject_cast<QWebView*>( widget ) ){
        setWindowTitle( webView->url().toString() );
    }else{
        setWindowTitle( "Ted V"TED_VERSION );
    }
}

//Main tab widget...
//
void MainWindow::updateTabLabel( QWidget *widget ){
    if( CodeEditor *editor=qobject_cast<CodeEditor*>( widget ) ){
        QString text=stripDir( editor->path() );
        if( editor->modified() ) text=text+"*";
        if( editor==_lockedEditor ) text="+"+text;
        _mainTabWidget->setTabText( _mainTabWidget->indexOf( widget ),text );
    }
}

void MainWindow::onCloseMainTab( int index ){

    closeFile( _mainTabWidget->widget( index ) );
}

void MainWindow::onMainTabChanged( int index ){

    CodeEditor *_oldEditor=_codeEditor;

    QWidget *widget=_mainTabWidget->widget( index );

    _codeEditor=qobject_cast<CodeEditor*>( widget );

    _helpWidget=qobject_cast<QWebView*>( widget );

    if( _oldEditor ){

        disconnect( _oldEditor,SIGNAL(showCode(QString,int)),this,SLOT(onShowCode(QString,int)) );
    }

    if( _codeEditor ){

        replaceTabWidgetWidget( _browserTabWidget,1,_codeEditor->codeTreeView() );

        connect( _codeEditor,SIGNAL(showCode(QString,int)),SLOT(onShowCode(QString,int)) );

        _codeEditor->setFocus( Qt::OtherFocusReason );

        onCursorPositionChanged();

    }else{

        replaceTabWidgetWidget( _browserTabWidget,1,_emptyCodeWidget );
    }

    updateWindowTitle();

    updateActions();
}

void MainWindow::onDockVisibilityChanged( bool visible ){

    updateActions();
}

//Project browser...
//
void MainWindow::onProjectMenu( const QPoint &pos ){

    QModelIndex index=_projectTreeWidget->indexAt( pos );
    if( !index.isValid() ) return;

    QFileInfo info=_projectTreeModel->fileInfo( index );

    QMenu *menu=0;

    if( _projectTreeModel->isProject( index ) ){
        menu=_projectPopupMenu;
    }else if( info.isFile() ){
        menu=_filePopupMenu;
    }else{
        menu=_dirPopupMenu;
    }

    if( !menu ) return;

    QAction *action=menu->exec( _projectTreeWidget->mapToGlobal( pos ) );
    if( !action ) return;

    if( action==_ui->actionNewFile ){

        bool ok=false;
        QString name=QInputDialog::getText( this,"Create File","File name: "+info.filePath()+"/",QLineEdit::Normal,"",&ok );
        if( ok && !name.isEmpty() ){
            if( extractExt( name ).isEmpty() ) name+=".monkey";
            QString path=info.filePath()+"/"+name;
            newFile( path );
        }

    }else if( action==_ui->actionNewFolder ){

        bool ok=false;
        QString name=QInputDialog::getText( this,"Create Folder","Folder name: "+info.filePath()+"/",QLineEdit::Normal,"",&ok );
        if( ok && !name.isEmpty() ){
            if( !QDir( info.filePath() ).mkdir( name ) ){
                QMessageBox::warning( this,"Create Folder","Create folder failed" );
            }
        }

    }else if( action==_ui->actionRenameFile ){

        bool ok=false;
        QString newName=QInputDialog::getText( this,"Rename file","New name:",QLineEdit::Normal,info.fileName(),&ok );
        if( ok ){
            QString oldPath=info.filePath();
            QString newPath=info.path()+"/"+newName;
            if( QFile::rename( oldPath,newPath ) ){
                for( int i=0;i<_mainTabWidget->count();++i ){
                    if( CodeEditor *editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) ) ){
                        if( editor->path()==oldPath ){
                            editor->rename( newPath );
                            updateTabLabel( editor );
                        }
                    }
                }
            }else{
                QMessageBox::warning( this,"Rename Error","Error renaming file: "+oldPath );
            }
        }
    }else if( action==_ui->actionOpen_on_Desktop ){

        QDesktopServices::openUrl( "file:/"+info.filePath() );

    }else if( action==_ui->actionDeleteFile ){

        QString path=info.filePath();

        if( info.isDir() ){
            if( QMessageBox::question( this,"Delete file","Okay to delete directory: "+path+" ?\n\n*** WARNING *** all subdirectories will also be deleted!",QMessageBox::Ok|QMessageBox::Cancel,QMessageBox::Cancel )==QMessageBox::Ok ){
                if( !removeDir( path ) ){
                    QMessageBox::warning( this,"Delete Error","Error deleting directory: "+info.filePath() );
                }
            }
        }else{
            if( QMessageBox::question( this,"Delete file","Okay to delete file: "+path+" ?",QMessageBox::Ok|QMessageBox::Cancel,QMessageBox::Cancel )==QMessageBox::Ok ){
                if( QFile::remove( path ) ){
                    for( int i=0;i<_mainTabWidget->count();++i ){
                        if( CodeEditor *editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) ) ){
                            if( editor->path()==path ){
                                closeFile( editor );
                                i=-1;
                            }
                        }
                    }
                }else{
                    QMessageBox::warning( this,"Delete Error","Error deleting file: "+info.filePath() );
                }
            }
        }
    }else if( action==_ui->actionCloseProject ){

        _projectTreeModel->removeProject( info.filePath() );

    }else if( action==_ui->actionEditFindInFiles ){

        _findInFilesDialog->show( info.filePath() );

        _findInFilesDialog->raise();

    }
}

void MainWindow::onFileClicked( const QModelIndex &index ){

    if( !_projectTreeModel->isDir( index ) ) openFile( _projectTreeModel->filePath( index ),true );
}

//Editor...
//
void MainWindow::onTextChanged(){
    if( CodeEditor *editor=qobject_cast<CodeEditor*>( sender() ) ){
        if( editor->modified()<2 ){
            updateTabLabel( editor );
        }
    }
    updateActions();
}

void MainWindow::onCursorPositionChanged(){
    if( sender()==_codeEditor ){
        _statusWidget->setText( "Line: "+QString::number( _codeEditor->textCursor().blockNumber()+1 ) );
    }
    updateActions();
}

void MainWindow::onShowCode( const QString &path,int line ){
    if( CodeEditor *editor=qobject_cast<CodeEditor*>( openFile( path,true ) ) ){
        //
        editor->gotoLine( line );
        editor->highlightLine( line );
        //
        if( editor==_codeEditor ) editor->setFocus( Qt::OtherFocusReason );
    }
}

void MainWindow::onShowCode( const QString &path,int pos,int len ){
    if( CodeEditor *editor=qobject_cast<CodeEditor*>( openFile( path,true ) ) ){
        //
        QTextCursor cursor( editor->document() );
        cursor.setPosition( pos );
        cursor.setPosition( pos+len,QTextCursor::KeepAnchor );
        editor->setTextCursor( cursor );
        //
        if( editor==_codeEditor ) editor->setFocus( Qt::OtherFocusReason );
    }
}

//Console...
//
void MainWindow::print( const QString &str ){
    QTextCursor cursor=_consoleTextWidget->textCursor();
    cursor.insertText( str );
    cursor.insertBlock();
    cursor.movePosition( QTextCursor::End,QTextCursor::MoveAnchor );
    _consoleTextWidget->setTextCursor( cursor );
    //_consoleTextWidget->insertPlainText( str+"\n" );
    //_consoleTextWidget->append( str );
}

void MainWindow::cdebug( const QString &str ){
    _consoleTextWidget->setTextColor( QColor( 128,0,128 ) );
    print( str );
}

void MainWindow::runCommand( QString cmd,QWidget *fileWidget ){

    cmd=cmd.replace( "${TARGET}",_targetsWidget->currentText().replace( ' ','_' ) );
    cmd=cmd.replace( "${CONFIG}",_configsWidget->currentText() );
    cmd=cmd.replace( "${MONKEYPATH}",_monkeyPath );
    cmd=cmd.replace( "${BLITZMAXPATH}",_blitzmaxPath );
    if( fileWidget ) cmd=cmd.replace( "${FILEPATH}",widgetPath( fileWidget ) );

    _consoleProc=new Process;

    connect( _consoleProc,SIGNAL(lineAvailable(int)),SLOT(onProcLineAvailable(int)) );//,Qt::QueuedConnection );
    connect( _consoleProc,SIGNAL(finished()),SLOT(onProcFinished()) );//,Qt::QueuedConnection );

    _consoleTextWidget->clear();
    _consoleDockWidget->show();
    _consoleTextWidget->setTextColor( QColor( 0,0,255 ) );
    print( cmd );

    if( !_consoleProc->start( cmd ) ){
        delete _consoleProc;
        _consoleProc=0;
        QMessageBox::warning( this,"Process Error","Failed to start process: "+cmd );
        return;
    }

    updateActions();
}

void MainWindow::onProcStdout(){

    static QString comerr=" : Error : ";
    static QString runerr="Monkey Runtime Error : ";

    QString text=_consoleProc->readLine( 0 );

    _consoleTextWidget->setTextColor( QColor( 0,0,0 ) );
    print( text );

    if( text.contains( comerr )){
        int i0=text.indexOf( comerr );
        QString info=text.left( i0 );
        int i=info.lastIndexOf( '<' );
        if( i!=-1 && info.endsWith( '>' ) ){
            QString path=info.left( i );
            int line=info.mid( i+1,info.length()-i-2 ).toInt()-1;
            QString err=text.mid( i0+comerr.length() );

            onShowCode( path,line );

            QMessageBox::warning( this,"Compile Error",err );
        }
    }else if( text.startsWith( runerr ) ){
        QString err=text.mid( runerr.length() );

        //not sure what this voodoo is for...!
        showNormal();
        raise();
        activateWindow();
        QMessageBox::warning( this,"Monkey Runtime Error",err );
    }
}

void MainWindow::onProcStderr(){

    if( _debugTreeModel && _debugTreeModel->stopped() ) return;

    QString text=_consoleProc->readLine( 1 );

    if( text.startsWith( "{{~~" ) && text.endsWith( "~~}}" ) ){

        QString info=text.mid( 4,text.length()-8 );

        int i=info.lastIndexOf( '<' );
        if( i!=-1 && info.endsWith( '>' ) ){
            QString path=info.left( i );
            int line=info.mid( i+1,info.length()-i-2 ).toInt()-1;
            onShowCode( path,line );
        }else{
            _consoleTextWidget->setTextColor( QColor( 255,128,0 ) );
            print( info );
        }

        if( !_debugTreeModel ){

            raise();

            _debugTreeModel=new DebugTreeModel( _consoleProc );
            connect( _debugTreeModel,SIGNAL(showCode(QString,int)),SLOT(onShowCode(QString,int)) );

            _debugTreeWidget->setModel( _debugTreeModel );
            connect( _debugTreeWidget,SIGNAL(clicked(const QModelIndex&)),_debugTreeModel,SLOT(onClicked(const QModelIndex&)) );

            _browserTabWidget->setCurrentWidget( _debugTreeWidget );

            _consoleTextWidget->setTextColor( QColor( 192,96,0 ) );
            print( "STOPPED" );
        }

        _debugTreeModel->stop();

        updateActions();

        return;
    }

    _consoleTextWidget->setTextColor( QColor( 128,0,0 ) );
    print( text );
}

void MainWindow::onProcLineAvailable( int channel ){

//    qDebug()<<"onProcLineAvailable";

    while( _consoleProc ){
        if( _consoleProc->isLineAvailable( 0 ) ){
            onProcStdout();
        }else if( _consoleProc->isLineAvailable( 1 ) ){
            onProcStderr();
        }else{
            return;
        }
    }
/*
    if( channel==0 ){
        onProcStdout();
    }else if( channel==1 ){
        onProcStderr();
    }
*/
}

void MainWindow::onProcFinished(){

//    qDebug()<<"onProcFinished. Flushing...";

    while( _consoleProc->waitLineAvailable( 0,100 ) ){
        onProcLineAvailable( 0 );
    }

//    qDebug()<<"Done.";

    _consoleTextWidget->setTextColor( QColor( 0,0,255 ) );
    print( "Done." );

    if( _debugTreeModel ){
        _debugTreeWidget->setModel( 0 );
        delete _debugTreeModel;
        _debugTreeModel=0;
    }

    if( _consoleProc ){
        delete _consoleProc;
        _consoleProc=0;
    }

    updateActions();

    statusBar()->showMessage( "Ready." );
}

void MainWindow::build( QString mode ){

    CodeEditor *editor=_lockedEditor ? _lockedEditor : _codeEditor;
    if( !isBuildable( editor ) ) return;

    QString filePath=editor->path();
    if( filePath.isEmpty() ) return;

    QString cmd,msg="Buillding: "+filePath+"...";

    if( editor->fileType()=="monkey" ){
        if( mode=="run" ){
            cmd="\"${MONKEYPATH}/bin/transcc"+HOST+"\" -target=${TARGET} -config=${CONFIG} -run \"${FILEPATH}\"";
        }else if( mode=="build" ){
            cmd="\"${MONKEYPATH}/bin/transcc"+HOST+"\" -target=${TARGET} -config=${CONFIG} \"${FILEPATH}\"";
        }else if( mode=="update" ){
            cmd="\"${MONKEYPATH}/bin/transcc"+HOST+"\" -target=${TARGET} -config=${CONFIG} -update \"${FILEPATH}\"";
            msg="Updating: "+filePath+"...";
        }else if( mode=="check" ){
            cmd="\"${MONKEYPATH}/bin/transcc"+HOST+"\" -target=${TARGET} -config=${CONFIG} -check \"${FILEPATH}\"";
            msg="Checking: "+filePath+"...";
        }
    }else if( editor->fileType()=="bmx" ){
        if( mode=="run" ){
            cmd="\"${BLITZMAXPATH}/bin/bmk\" makeapp -a -r -x ${FILEPATH}";
        }else if( mode=="build" ){
            cmd="\"${BLITZMAXPATH}/bin/bmk\" makeapp -a -x ${FILEPATH}";
        }
    }

    if( !cmd.length() ) return;

    onFileSaveAll();

    statusBar()->showMessage( msg );

    runCommand( cmd,editor );
}

//***** File menu *****

void MainWindow::onFileNew(){
    newFile( "" );
}

void MainWindow::onFileOpen(){
    openFile( "",true );
}

void MainWindow::onFileOpenRecent(){
    if( QAction *action=qobject_cast<QAction*>( sender() ) ){
        openFile( action->text(),false );
    }

}

void MainWindow::onFileClose(){
    closeFile( _mainTabWidget->currentWidget() );
}

void MainWindow::onFileCloseAll(){
    for(;;){
        int i;
        CodeEditor *editor=0;
        for( i=0;i<_mainTabWidget->count();++i ){
            if( editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) ) ) break;
        }
        if( !editor ) return;

        if( !closeFile( editor ) ) return;
    }
}

void MainWindow::onFileCloseOthers(){
    if( _helpWidget ) return onFileCloseAll();
    if( !_codeEditor ) return;

    for(;;){
        int i;
        QWidget *widget=0;
        CodeEditor *editor=0;
        for( i=0;i<_mainTabWidget->count();++i ){
            editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) );
            if( editor && editor!=_codeEditor ) break;
            editor=0;
        }
        if( !editor ) return;

        if( !closeFile( editor ) ) return;
    }
}

void MainWindow::onFileSave(){
    if( !_codeEditor ) return;

    saveFile( _codeEditor,_codeEditor->path() );
}

void MainWindow::onFileSaveAs(){
    if( !_codeEditor ) return;

    saveFile( _codeEditor,"" );
}

void MainWindow::onFileSaveAll(){
    for( int i=0;i<_mainTabWidget->count();++i ){
        CodeEditor *editor=qobject_cast<CodeEditor*>( _mainTabWidget->widget( i ) );
        if( editor && !saveFile( editor,editor->path() ) ) return;
    }
}

void MainWindow::onFileNext(){
    if( _mainTabWidget->count()<2 ) return;

    int i=_mainTabWidget->currentIndex()+1;
    if( i>=_mainTabWidget->count() ) i=0;

    _mainTabWidget->setCurrentIndex( i );
}

void MainWindow::onFilePrevious(){
    if( _mainTabWidget->count()<2 ) return;

    int i=_mainTabWidget->currentIndex()-1;
    if( i<0 ) i=_mainTabWidget->count()-1;

    _mainTabWidget->setCurrentIndex( i );
}

void MainWindow::onFilePrefs(){

    _prefsDialog->setModal( true );

    _prefsDialog->exec();

    Prefs *prefs=Prefs::prefs();

    QString path=prefs->getString( "monkeyPath" );
    if( path!=_monkeyPath ){
        if( isValidMonkeyPath( path ) ){
            _monkeyPath=path;
            enumTargets();
        }else{
            prefs->setValue( "monkeyPath",_monkeyPath );
            QMessageBox::warning( this,"Tool Path Error","Invalid Monkey Path" );
        }
    }

    path=prefs->getString( "blitzmaxPath" );
    if( path!=_blitzmaxPath ){
        if( isValidBlitzmaxPath( path ) ){
            _blitzmaxPath=path;
        }else{
            prefs->setValue( "blitzmaxPath",_blitzmaxPath );
            QMessageBox::warning( this,"Tool Path Error","Invalid BlitzMax Path" );
        }
    }

    updateActions();
}

void MainWindow::onFileQuit(){
    if( confirmQuit() ) QApplication::quit();
}

//***** Edit menu *****

void MainWindow::onEditUndo(){
    if( !_codeEditor ) return;

    _codeEditor->undo();
}

void MainWindow::onEditRedo(){
    if( !_codeEditor ) return;

    _codeEditor->redo();
}

void MainWindow::onEditCut(){
    if( !_codeEditor ) return;

    _codeEditor->cut();
}

void MainWindow::onEditCopy(){
    if( !_codeEditor ) return;

    _codeEditor->copy();
}

void MainWindow::onEditPaste(){
    if( !_codeEditor ) return;

    _codeEditor->paste();
}

void MainWindow::onEditDelete(){
    if( !_codeEditor ) return;

    _codeEditor->textCursor().removeSelectedText();
}

void MainWindow::onEditSelectAll(){
    if( !_codeEditor ) return;

    _codeEditor->selectAll();

    updateActions();
}

void MainWindow::onEditFind(){
    if( !_codeEditor ) return;

    _findDialog->setModal( true );

    _findDialog->exec();
}

void MainWindow::onEditFindNext(){
    if( !_codeEditor ) return;

    onFindReplace( 0 );
}

void MainWindow::onFindReplace( int how ){
    if( !_codeEditor ) return;

    QString findText=_findDialog->findText();
    if( findText.isEmpty() ) return;

    QString replaceText=_findDialog->replaceText();

    bool cased=_findDialog->caseSensitive();

    bool wrap=true;

    if( how==0 ){

        if( !_codeEditor->findNext( findText,cased,wrap ) ){
            QApplication::beep();
//            QMessageBox::information( this,"Find Next","Text not found" );
//            _findDialog->activateWindow();
        }

    }else if( how==1 ){

        if( _codeEditor->replace( findText,replaceText,cased ) ){
            if( !_codeEditor->findNext( findText,cased,wrap ) ){
                QApplication::beep();
//                QMessageBox::information( this,"Replace","Text not found" );
//                _findDialog->activateWindow();
            }
        }


    }else if( how==2 ){

        int n=_codeEditor->replaceAll( findText,replaceText,cased,wrap );

        QMessageBox::information( this,"Replace All",QString::number(n)+" occurences replaced" );
    }
}

void MainWindow::onEditGoto(){
    if( !_codeEditor ) return;

    bool ok=false;
    int line=QInputDialog::getInt( this,"Go to Line","Line number:",1,1,_codeEditor->document()->blockCount(),1,&ok );
    if( ok ){
        _codeEditor->gotoLine( line-1 );
        _codeEditor->highlightLine( line-1 );
    }
}

void MainWindow::onEditFindInFiles(){

    _findInFilesDialog->show();

    _findInFilesDialog->raise();
}

//***** View menu *****

void MainWindow::onViewToolBar(){
    if( sender()==_ui->actionViewFile ){
        _ui->fileToolBar->setVisible( _ui->actionViewFile->isChecked() );
    }else if( sender()==_ui->actionViewEdit ){
        _ui->editToolBar->setVisible( _ui->actionViewEdit->isChecked() );
    }else if( sender()==_ui->actionViewBuild ){
        _ui->buildToolBar->setVisible( _ui->actionViewBuild->isChecked() );
    }else if( sender()==_ui->actionViewHelp ){
        _ui->helpToolBar->setVisible( _ui->actionViewHelp->isChecked() );
    }
}

void MainWindow::onViewWindow(){
    if( sender()==_ui->actionViewBrowser ){
        _browserDockWidget->setVisible( _ui->actionViewBrowser->isChecked() );
    }else if( sender()==_ui->actionViewConsole ){
        _consoleDockWidget->setVisible( _ui->actionViewConsole->isChecked() );
    }
}

//***** Build menu *****

void MainWindow::onBuildBuild(){
    build( "build" );
}

void MainWindow::onBuildRun(){
    if( _debugTreeModel ){
        _debugTreeModel->run();
    }else{
        build( "run" );
    }
}

void MainWindow::onBuildCheck(){
    build( "check" );
}

void MainWindow::onBuildUpdate(){
    build( "update" );
}

void MainWindow::onDebugStep(){
    if( !_debugTreeModel ) return;
    _debugTreeModel->step();
}

void MainWindow::onDebugStepInto(){
    if( !_debugTreeModel ) return;
    _debugTreeModel->stepInto();
}

void MainWindow::onDebugStepOut(){
    if( !_debugTreeModel ) return;
    _debugTreeModel->stepOut();
}

void MainWindow::onDebugKill(){
    if( !_consoleProc ) return;

    _consoleTextWidget->setTextColor( QColor( 0,0,255 ) );
    print( "Killing process..." );

    _consoleProc->kill();
}

void MainWindow::onBuildTarget(){

    QStringList items;
    for( int i=0;i<_targetsWidget->count();++i ){
        items.push_back( _targetsWidget->itemText( i ) );
    }

    bool ok=false;
    QString item=QInputDialog::getItem( this,"Select build target","Build target:",items,_targetsWidget->currentIndex(),false,&ok );
    if( ok ){
        int index=items.indexOf( item );
        if( index!=-1 ) _targetsWidget->setCurrentIndex( index );
    }
}

void MainWindow::onBuildConfig(){

    QStringList items;
    for( int i=0;i<_configsWidget->count();++i ){
        items.push_back( _configsWidget->itemText( i ) );
    }

    bool ok=false;
    QString item=QInputDialog::getItem( this,"Select build config","Build config:",items,_configsWidget->currentIndex(),false,&ok );
    if( ok ){
        int index=items.indexOf( item );
        if( index!=-1 ) _configsWidget->setCurrentIndex( index );
    }
}

void MainWindow::onBuildLockFile(){
    if( _codeEditor && _codeEditor!=_lockedEditor ){
        CodeEditor *wasLocked=_lockedEditor;
        _lockedEditor=_codeEditor;
        updateTabLabel( _lockedEditor );
        if( wasLocked ) updateTabLabel( wasLocked );
    }
    updateActions();
}

void MainWindow::onBuildUnlockFile(){
    if( CodeEditor *wasLocked=_lockedEditor ){
        _lockedEditor=0;
        updateTabLabel( wasLocked );
    }
    updateActions();
}

void MainWindow::onBuildAddProject(){

    QString dir=fixPath( QFileDialog::getExistingDirectory( this,"Select project directory",_defaultDir,QFileDialog::ShowDirsOnly|QFileDialog::DontResolveSymlinks ) );
    if( dir.isEmpty() ) return;

    if( !_projectTreeModel->addProject( dir ) ){
        QMessageBox::warning( this,"Add Project Error","Error adding project: "+dir );
    }
}

//***** Help menu *****

void MainWindow::onHelpHome(){

    QString htmlDocs=_monkeyPath+"/docs/html/Home.html";

    if( QFile::exists( htmlDocs ) ){
        openFile( "file:///"+htmlDocs,false );
    }else{
        openFile( "file:///"+_monkeyPath+"/docs/blitz-wiki.appspot.com/index4d8a.html",false );
    }
}

void MainWindow::onHelpBack(){
    if( !_helpWidget ) return;

    _helpWidget->back();
}

void MainWindow::onHelpForward(){
    if( !_helpWidget ) return;

    _helpWidget->forward();
}

void MainWindow::onHelpQuickHelp(){
    if( !_codeEditor ) return;

    QString ident=_codeEditor->identAtCursor();
    if( ident.isEmpty() ) return;

    onShowHelp( ident );
}

void MainWindow::onHelpAbout(){
    QString ABOUT=
            "Ted V"TED_VERSION"  (QT_VERSION "_STRINGIZE(QT_VERSION)"; Trans V"+_transVersion+")\n\n"
            "Copyright Blitz Research Ltd.\n\n"
            "A simple editor/IDE for the Monkey programming language.\n\n"
            "Please visit www.monkeycoder.co.nz for more information on Monkey."
            ;

    QMessageBox::information( this,"About Ted",ABOUT );
}

void MainWindow::onShowHelp( const QString &topic ){

    QString url=_helpUrls.value( topic );
    if( url.isEmpty() ) return;

    openFile( url,false );
}

void MainWindow::onLinkClicked( const QUrl &url ){

    QString str=url.toString();
    QString lstr=str.toLower();

    if( lstr.startsWith( "file:///" ) ){
        QString ext=";"+extractExt(lstr)+";";
        if( textFileTypes.contains( ext ) || codeFileTypes.contains( ext ) ){
            openFile( str.mid( 8 ),false );
            return;
        }
        openFile( str,false );
        return;
    }

    QDesktopServices::openUrl( str );
/*
    qDebug()<<"Opening:"<<str;

    openFile( str,false );
*/
}

void MainWindow::onHelpRebuild(){
    if( _consoleProc || _monkeyPath.isEmpty() ) return;

    onFileSaveAll();

    QString cmd="\"${MONKEYPATH}/bin/makedocs"+HOST+"\"";

    runCommand( cmd,0 );

    loadHelpIndex();

    for( int i=0;i<_mainTabWidget->count();++i ){
        QWebView *webView=qobject_cast<QWebView*>( _mainTabWidget->widget( i ) );

        if( webView ) webView->triggerPageAction( QWebPage::ReloadAndBypassCache );
//        if( webView ) webView->reload();
    }
}
