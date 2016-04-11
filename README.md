# omedeto #

### Dependence ###

+ Node.js v0.12.xx

事前にグローバルインストールをしておいてください。
(mongoWrpperがES6で書いてあるため、babel5のインストールが要る)

```bash
$ nvm install 0.12.xx
$ nvm use 0.12.xx
$ npm install -g gulp
$ npm install -g bower
$ npm install -g babel@5
$ npm install -g pm2
```

　

### Source ###

```bash
.
├── README.md              // README
├── gulpfile.js
├── app.js
├── config.js              // server setting
├── package.json           // module management
├── node_modules           // module
├── routes                 // function
├── views                  // jade
├── dist                   // client code
│      ├── fonts
│      ├── images
│      ├── javascripts
│      └── stylesheets
├── vendor                 // vendor code
│      ├── fonts
│      ├── images
│      ├── javascripts
│      └── stylesheets
├── src                   // src code
│      ├── gulpfile.coffee
│      ├── app.coffee     // server
│      ├── config.coffee  // config
│      ├── routes         // routing
│      ├── coffee         // coffeescript
│      ├── stylus         // stylus	
│      └── images         // images
└── upload                // upload temporary file
```

　
	
### Install ###

```bash
$ cd omedeto
$ npm install
$ bower install
```

### Build ###

srcディレクトリの中身を展開します。

```bash
$ gulp build
```

実行されるタスク

+ clean
+ coffeeScriptコンパイル
+ stylusコンパイル
+ image圧縮コピー
+ vendorファイルコピー

### Start Application ###

開発環境用に起動します。

```bash
$ gulp
```

実行されるタスク

+ coffeeScriptコンパイル
+ stylusコンパイル
+ node起動
+ ファイル変更監視

本版環境用に起動します。

```bash
$ npm start
```
