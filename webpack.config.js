const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const TerserPlugin = require("terser-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const WebpackObfuscator = require("webpack-obfuscator");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
  mode: "production",
  entry: "./public/main.js", // Entry point (main.js)
  output: {
    filename: "bundle.js", // Output minimized JS file
    path: path.resolve(__dirname, "dist"), // Output directory
    publicPath: "./",
  },
  module: {
    rules: [
      {
        test: /\.css$/, // Process only .css files
        use: ["style-loader", "css-loader", "postcss-loader"],
        exclude: /node_modules/,
      },
      {
        test: /\.html$/, // Process HTML files
        use: ["html-loader"],
        exclude: /node_modules/,
      },
      {
        test: /\.(png|gif|jpe?g|svg)$/, // Process image files
        type: "asset/resource",
      },
    ],
  },
  optimization: {
    minimize: true, // Keep JS minification active
    minimizer: [
      new TerserPlugin({ // Keep JS minified
        terserOptions: {
          format: {
            comments: false,
          },
        },
        extractComments: false,
      }),
      // Remove CssMinimizerPlugin to disable CSS minification
    ],
  },
  plugins: [
    new CleanWebpackPlugin(), // Cleans old builds
    new HtmlWebpackPlugin({
      template: path.resolve(__dirname, "public/index.html"), // Uses your index.html
      filename: "index.html",
      inject: "body",
      minify: {
        collapseWhitespace: true,
        removeComments: true,
        removeRedundantAttributes: true,
      },
    }),
    new WebpackObfuscator(
      {
        rotateStringArray: true,
        stringArray: true,
        deadCodeInjection: true,
        debugProtection: true,
      },
      ["excluded.js"]
    ),
    new CopyWebpackPlugin({
      patterns: [
        { from: path.resolve(__dirname, "public/favicon-16x16.png"), to: "favicon-16x16.png" },
        { from: path.resolve(__dirname, "public/spinner.gif"), to: "spinner.gif" },
        { from: path.resolve(__dirname, "public/styles.css"), to: "styles.css" },
      ],
    }),
  ],
  devServer: {
    static: path.join(__dirname, "dist"),
    compress: true,
    port: 8080,
  },
  stats: {
    children: true, // Enable detailed stats for child compilations
  },
};