const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const { CleanWebpackPlugin } = require('clean-webpack-plugin');
const BundleAnalyzerPlugin = !!process.env.PROFILE ? require('webpack-bundle-analyzer').BundleAnalyzerPlugin : undefined;
const isProduction = process.argv.indexOf('-p') != -1;

const config = {
    mode: isProduction ? 'production' : 'development',
    entry: './src/index.tsx',
    output: {
        filename: "js/[hash].js",
        path: __dirname + "/public"
    },

    // Enable sourcemaps for debugging webpack's output.
    devtool: "source-map",

    module: {
        rules: [
            {
              test: /\.tsx?$/,
              loader: "ts-loader",
              options: {
                transpileOnly: isProduction
              },
            },

            {
              enforce: "pre",
              test: /\.js$/,
              loader: "source-map-loader"
            },

            {
              test: /\.ejs$/,
              loader: 'ejs-compiled-loader'
            },

            {
              test: /\.css$/i,
              use: ['style-loader', 'css-loader'],
            },
        ]
    },

    resolve: {
      extensions: ['.ts', '.tsx', '.js', '.jsx', '.json', '.css', '.sass', '.scss'],
      alias: {
        "react": "preact/compat",
        "react-dom": "preact/compat"
      }
    },

    performance: {
      hints: false
    },

    plugins: [
      //new CleanWebpackPlugin(),
      new HtmlWebpackPlugin({
        title: 'Fitba',
        template: 'src/index.ejs',
        filename: 'index.html'
      }),
    ],
};

if (BundleAnalyzerPlugin !== undefined) {
  config.plugins.push(new BundleAnalyzerPlugin());
}

module.exports = config;
