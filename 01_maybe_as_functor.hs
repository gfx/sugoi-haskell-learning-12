-- Maybe Functorの復習

-- class Functor f where
--     fmap :: (a -> b) -> f a -> f b

-- pp. 152-153 (§7.10 Functor型クラス)

-- instance Functor Maybe where
--     fmap f (Just x) = (Just f x)
--     fmap f Nothing = Nothing

main = do
    putStrLn $ show $ fmap (+ 5) $ Just 10 -- Just 15
    putStrLn $ show $ fmap (* 5) $ Just 10 -- Just 50
    putStrLn $ show $ fmap (* 5) $ Nothing  -- Nothing

