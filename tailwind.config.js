// shadcn-uiにtailwindを認識してもらうため、形式的に設定ファイルを追加
module.exports = {
    content: [
        "./app/views/**/*.{html,erb,rb}",
        "./app/helpers/**/*.rb",
        "./app/javascript/**/*.js",
        "./app/assets/stylesheets/**/*.css"
    ],
    theme: {
        extend: {},
    },
    plugins: [],
}
