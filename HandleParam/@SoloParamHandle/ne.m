function [t] = ne(u1, u2)
   
   t = (value(u1) ~= value(u2));
   