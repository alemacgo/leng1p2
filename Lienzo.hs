module Lienzo (Lienzo,
               Posicion,
               dimensiones,
               lienzoValido,
               lienzoVacio,
               lienzoNuevo,
               dibujarPunto,
               obtenerColor,
               dibujarLinea,
               dibujarCirculo,
               dibujarCurva,
               llenar) where

import Utilidades
import Data.List
import Debug.Trace

data Lienzo = MkLienzo { dimensiones :: (Int, Int),
                         matriz :: [[Char]] }

type Posicion = (Int, Int)

instance (Show Lienzo) where
    show (MkLienzo (x, y) z) = foldl (++) []
     [take (y+1) $ repeat '*', "*\n*", concatMap (++ "*\n*") z, (take (y+1) $ repeat '*')]

lienzoValido :: Lienzo -> Bool
lienzoValido (MkLienzo (0, m) []) = True -- ??
lienzoValido (MkLienzo (n + 1, m) lista) = (n + 1 == length lista) && 
                                           (and $ map (\xs -> m == length xs) lista)
lienzoValido _ = False 

lienzoNuevo :: (Int, Int) -> Char -> Lienzo
lienzoNuevo (x, y) c
    | x < 0 || y < 0 = error "Las dimensiones del lienzo deben ser no negativas"
    | otherwise = MkLienzo (x, y) (take x $ repeat $ take y $ repeat c) -- repeat.take

lienzoVacio :: (Int, Int) -> Lienzo
lienzoVacio pos = lienzoNuevo pos ' ' 
                              
obtenerColor :: Lienzo -> Posicion -> Char
obtenerColor (MkLienzo (x, y) lista) (x1, y1)
    | x1 >= x || y1 >= y = error "El punto esta fuera del lienzo"
    | otherwise = lista !! x1 !! y1 
    
-- Más compacto? otro reemplazar
dibujarPunto :: Lienzo -> Posicion -> Char -> Lienzo
dibujarPunto (MkLienzo (x, y) lista) (x1, y1) c
    | x1 >= x || y1 >= y = error "El punto esta fuera del lienzo"
    | otherwise = MkLienzo (x, y) (sustituirLista lista x1 y1 c)
        where sustituirLista (z:zs) x1 y1 c
                    | x1 == 0 = (reemplazar c y1 z):zs
                    | otherwise = z:(sustituirLista zs (x1-1) y1 c) 

-- Punto inicial -> Angulo -> Longitud -> Puntos de la linea
obtenerLinea :: Posicion -> Float -> Int -> [Posicion]
obtenerLinea (x,y) ang l
    | l > 0 =  posicionNueva : obtenerLinea (x,y) ang (l-1)
    | l == 0 = [posicionNueva]
    | l < 0 = error "La longitud es negativa"
        where posicionNueva = (truncate $ fromIntegral x - l' * sin ang', 
                               truncate $ fromIntegral y + l' * cos ang')
              l' = fromIntegral l
              ang' = aRadianes ang

obtenerCirculo :: Posicion -> Int -> Int -> Int -> [Posicion]
obtenerCirculo (x,y) r ang fin
    | ang < fin =  posicionNueva : obtenerCirculo (x,y) r (ang + 1) fin
    | ang == fin = [posicionNueva]
        where ang' = aRadianes $ fromIntegral ang
              r' = fromIntegral r
              posicionNueva = (round $ fromIntegral x + r' * sin ang', 
                               round $ fromIntegral y + r' * cos ang')

-- como hacer esto con map y filter?
dibujarPuntos :: Lienzo -> [Posicion] -> Char -> Lienzo
dibujarPuntos lienzo@(MkLienzo (x, y) lista) ((x1, y1):xs) c
    | fueraDelLienzo = dibujarPuntos lienzo xs c
    | otherwise = dibujarPuntos (dibujarPunto lienzo (x1, y1) c) xs c
        where fueraDelLienzo = x <= x1 || y <= y1 || x1 < 0 || y1 < 0
dibujarPuntos lienzo [] _ = lienzo

-- Punto inicial -> Angulo -> Longitud -> Puntos de la linea
dibujarLinea :: Lienzo -> Posicion -> Float -> Int -> Char -> Lienzo
dibujarLinea lienzo pos ang l c = dibujarPuntos lienzo (obtenerLinea pos ang l) c

dibujarCirculo :: Lienzo -> Posicion -> Int -> Char -> Lienzo
dibujarCirculo lienzo pos r c
    | r < 0 = error "El radio del circulo debe ser no negativo"
    | otherwise = dibujarPuntos lienzo (obtenerCirculo pos r 0 360) c

llenar :: Lienzo -> Posicion -> Char -> Lienzo
llenar lienzo@(MkLienzo (x, y) lista) pos@(x1, y1) c
        | fueraDelLienzo = error "La posicion se encuentra fuera del lienzo"
        | otherwise = rellenar lienzo (obtenerColor lienzo pos) c pos
            where fueraDelLienzo = x <= x1 || y <= y1 || x1 < 0 || y1 < 0 

rellenar :: Lienzo -> Char -> Char -> Posicion -> Lienzo
rellenar lienzo@(MkLienzo (x, y) lista) c1 c2 pos@(x1, y1)
    | fueraDelLienzo || obtenerColor lienzo pos /= c1 = lienzo
    | otherwise = rellenar (
                    rellenar (
                      rellenar (
                        rellenar (dibujarPunto lienzo pos c2) c1 c2 (x1 + 1, y1)
                      ) c1 c2 (x1 - 1, y1)
                    ) c1 c2 (x1, y1 + 1)
                  ) c1 c2 (x1, y1 - 1)
        where fueraDelLienzo = x <= x1 || y <= y1 || x1 < 0 || y1 < 0    

-- Poner bonito desde aqui

eliminarPuntosInnecesarios :: Posicion -> [Posicion] -> [Posicion]
eliminarPuntosInnecesarios (x, y) ((x1, y1):xs) 
    | x1 > x || x1 < 0 || y1 > y || y1 < 0 = eliminarPuntosInnecesarios (x, y) xs
    | otherwise = (x1, y1) : eliminarPuntosInnecesarios (x, y) (eliminarIguales (x1, y1) xs)
        where eliminarIguales (x1, y1) xs = [(x2, y2) | (x2, y2) <- xs, x2 /= x1 || y2 /= y1]
    
dibujarCurva :: Lienzo -> Posicion -> Int -> Int -> Char -> Lienzo
dibujarCurva lienzo@(MkLienzo pos1 lista) pos r lon c
    | lon < 0  || r < 0 = error "La longitud de la curva debe ser no negativa"
    | otherwise = dibujarPuntos lienzo (take lon (eliminarPuntosInnecesarios 
        pos1 (clasificar pos (obtenerCirculo pos r 180 540)))) c

clasificar :: Posicion -> [Posicion] -> [Posicion]
clasificar (x, y) xs = sortBy (ordenTuplas) [(x1, y1) | (x1, y1) <- xs, x1 >= x]
                        ++ reverse (sortBy (ordenTuplas) [(x1, y1) | (x1, y1) <- xs, x1 <= x])

dibujarPoligono :: Lienzo -> [Posicion] -> Char -> Lienzo
dibujarPoligono lienzo@(MkLienzo pos lista) (p@(x1, y1):p2@(x2, y2):ps) c =
    trace (show $ aGrados alfa) dibujarPoligono (dibujarLinea lienzo p (aGrados alfa) hipotenusa c) (p2:ps) c
    where alfa = (normalizar x1 y1 x2 y2) * (atan $ (fromIntegral (y1 - y2))/(fromIntegral (x1-x2)))
          hipotenusa = truncate $ sqrt $ fromIntegral ((x1 - x2)^2 + (y1 - y2)^2)

dibujarPoligono lienzo _ _ = lienzo

--let p1 = (20,15) :: (Int, Int)
--let p2 = (10,15) :: (Int, Int)
--let p3 = (15,20) :: (Int, Int)
--let x = (dibujarPunto (dibujarPunto (dibujarPunto (lienzoVacio (30,30)) (20,15) ('+')) (10,15) '+') (15,20) '+') 
