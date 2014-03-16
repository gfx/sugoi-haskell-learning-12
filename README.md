# すごいHaskell楽しく学ぼう！輪読会

http://sugoihaskell.github.io/

2014/3/17 by gfx

# 第12章 モノイド


## モノイドの前に - newtype

* `newtype` は既存の型から新しい型を作る
* 意味的にはフィールドをひとつだけ持つ `data` とほぼ同じ
* `type` と異なり、完全に新しい型をつくるので、導出元の型に対する関数は呼び出せない

### 復習: ファンクタとしてのタプル

MaybeはFunctorとして振る舞えるのだった。その挙動は、「NothingでなければfをJustの中身に適用してJustで包み直す」というものだった。


```haskell
-- Maybe Functorの定義:
-- instance Functor Maybe where
--     fmap f (Just x) = (Just f x)
--     fmap f Nothing = Nothing

fmap (+ 5) $ Just 10 -- Just 15
fmap (* 5) $ Just 10 -- Just 50
fmap (* 5) $ Nothing  -- Nothing
```

2要素タプルもFunctorとして振る舞う。その振る舞いは、第二要素に対してfを適用した結果を返すというものだった。

```haskell
fmap (+ 5) (10, 20) -- (10, 25)
fmap (+ 5) ("foo", 20) -- ("foo", 25)
```

それでは、第一要素に対してfを適用するような `fmap` はどうやって定義したらいいだろう？
そこで `newtype` が使える！

```haskell
-- data でも結果はかわらない（showしたときの結果も含めて）
newtype Pair b a = Pair { getPair :: (a, b) } deriving Show

instance Functor (Pair c) where
    fmap f (Pair (x, y)) = Pair (f x, y)

main = do
    let p = Pair (10, 20)
    putStrLn $ show $ p  -- Pair {getPair = (10,20)}
    putStrLn $ show $ getPair p  -- (10,20)
    putStrLn $ show $ fmap (+ 5) $ p -- Pair {getPair = (15,20)}
    putStrLn $ show $ fmap (+ 5) $ getPair p -- (10,25)
```

これを踏まえて、次へ進もう

## モノイド型クラス

